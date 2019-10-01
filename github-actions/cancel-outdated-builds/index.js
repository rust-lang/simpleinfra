const actions = require("@actions/core");
const childProcess = require("child_process");
const fetch = require("node-fetch");
const psList = require("ps-list");

const WORKER_NAME = "Runner.Worker";
const CHECK_EVERY_SECONDS = 1;

const main = (async () => {
    while (true) {
        if (await isLatestCommit() === false) {
            let pid = await findWorkerPid();
            if (pid !== null) {
                process.kill(pid, 'SIGTERM');
                return;
            }
        }
        await new Promise(resolve => setTimeout(resolve, CHECK_EVERY_SECONDS * 1000));
    }
});

const isLatestCommit = async () => {
    let commit = process.env["GITHUB_SHA"];
    let ref = process.env["GITHUB_REF"];
    let repo = process.env["GITHUB_REPOSITORY"];
    let token = process.env["GITHUB_TOKEN"];

    let resp = await fetch("https://api.github.com/repos/" + repo + "/commits/" + ref, {
        headers: {
            "If-None-Match": '"' + commit + '"',
            "Accept": "application/vnd.github.v3.sha",
            "Authorization": "token " + token,
        },
    });
    let current_commit = await resp.text();

    if (resp.status === 200 && current_commit !== commit) {
        // If-None-Match did not work, the commit changed
        return false;
    } else if (resp.status === 304) {
        // A "Not modified" was returned (without impacting the rate limits),
        // so the commit is indeed the last one
        return true;
    } else {
        actions.setFailed("Failed to fetch the latest commit!");
        process.exit(1);
    }
};

const daemonize = async () => {
    let worker_pid = await findWorkerPid();
    if (worker_pid === null) {
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
    let proc = (await psList()).find(proc => proc.name === WORKER_NAME);
    if (proc === undefined) {
        return null;
    } else {
        return proc.pid;
    }
}

if (process.argv.length == 3 && process.argv[2] == "foreground") {
    main();
} else {
    daemonize();
}
