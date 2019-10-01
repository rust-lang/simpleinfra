const actions = require("@actions/core");
const childProcess = require("child_process");
const fetch = require("node-fetch");
const psList = require("ps-list");

// Name of the process that will be killed when the build is outdated. On
// Windows `.exe` will be appended to the name.
const WORKER_NAME = "Runner.Worker";

const main = (async () => {
    let checkEverySeconds = parseInt(actions.getInput("check_every_seconds", { required: true }));
    while (true) {
        if (await isLatestCommit() === false) {
            let pid = await findWorkerPid();
            if (pid !== null) {
                process.kill(pid, 'SIGTERM');
            }
            return;
        }
        await new Promise(resolve => setTimeout(resolve, checkEverySeconds * 1000));
    }
});

const isLatestCommit = async () => {
    let commit = process.env["GITHUB_SHA"];
    let ref = process.env["GITHUB_REF"];
    let repo = process.env["GITHUB_REPOSITORY"];
    let token = actions.getInput("github_token", { required: true });

    let resp = await fetch("https://api.github.com/repos/" + repo + "/commits/" + ref, {
        headers: {
            "Accept": "application/vnd.github.v3.sha",
            "Authorization": "token " + token,
            // If-None-Match allows a periodic polling without hitting the rate
            // limits: when the commit is the same as the one provided in the
            // header GitHub will return a 304 status code without impacting
            // the limits.
            "If-None-Match": '"' + commit + '"',
        },
    });
    let currentCommit = await resp.text();

    if (resp.status === 200 && currentCommit !== commit) {
        // If-None-Match did not work, the commit changed
        return false;
    } else if (resp.status === 304) {
        // A "Not modified" was returned (without impacting the rate limits),
        // so the commit is indeed the last one
        return true;
    } else if (resp.status === 429) {
        // If we're rate limited just fake that the commit is the latest so it
        // will be checked later.
        return true;
    } else {
        actions.setFailed("Failed to fetch the latest commit!");
        process.exit(1);
    }
};

const daemonize = async () => {
    let workerPid = await findWorkerPid();
    if (workerPid === null) {
        actions.setFailed("A process named " + WORKER_NAME + " is not running!");
        return;
    }

    let subprocess = childProcess.fork(__filename, ["foreground"], {
        detached: true,
        stdio: "ignore",
    });
    subprocess.unref();

    actions.info("Successfully daemonized cancel-outdated-builds.");
    process.exit(0);
};

const findWorkerPid = async () => {
    let procName = binaryName(WORKER_NAME);
    let proc = (await psList()).find(proc => proc.name === procName);
    if (proc === undefined) {
        return null;
    } else {
        return proc.pid;
    }
}

const binaryName = name => {
    if (process.platform === "win32") {
        return name + ".exe";
    } else {
        return name;
    }
};

if (process.argv.length == 3 && process.argv[2] == "foreground") {
    main();
} else {
    daemonize();
}
