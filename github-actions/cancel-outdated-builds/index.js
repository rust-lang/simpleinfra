const actions = require("@actions/core");
const childProcess = require("child_process");
const fetch = require("node-fetch");

const main = (async () => {
    let checkEverySeconds = parseInt(actions.getInput("check_every_seconds", { required: true }));
    while (true) {
        if (await isLatestCommit() === false) {
            await cancelRun();
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

const cancelRun = async () => {
    let repo = process.env["GITHUB_REPOSITORY"];
    let run_id = process.env["GITHUB_RUN_ID"];
    let token = actions.getInput("github_token", { required: true });

    let resp = await fetch("https://api.github.com/repos/" + repo + "/actions/runs/" + run_id + "/cancel", {
        method: "POST",
        headers: {
            "Authorization": "token " + token,
        },
    });

    if (resp.status !== 202) {
        actions.setFailed(
            "Received unexpected status code " + resp.status + "while cancelling the build!"
        );
        process.exit(1);
    }
};

const daemonize = async () => {
    let subprocess = childProcess.fork(__filename, ["foreground"], {
        detached: true,
        stdio: "ignore",
    });
    subprocess.unref();

    actions.info("Successfully daemonized cancel-outdated-builds.");
    process.exit(0);
};

if (process.argv.length == 3 && process.argv[2] == "foreground") {
    main();
} else {
    daemonize();
}
