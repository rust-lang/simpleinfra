const AWS = require("aws-sdk");
const actions = require("@actions/core");
const base64 = require("base64-js");
const exec = require("@actions/exec");

const main = async () => {
    try {
        process.env["AWS_ACCESS_KEY_ID"] = actions.getInput("aws_access_key_id", { required: true });
        process.env["AWS_SECRET_ACCESS_KEY"] = actions.getInput("aws_secret_access_key", { required: true });

        let image = actions.getInput("image", { required: true });
        let repository = actions.getInput("repository", { required: true });
        let region = actions.getInput("region", { required: true });

        let sts = new AWS.STS();
        let ecr = new AWS.ECR({ region: region });

        let account_id = (await sts.getCallerIdentity().promise())["Account"];
        let auth = (await ecr.getAuthorizationToken().promise())["authorizationData"][0];

        let token = new TextDecoder("utf-8").decode(base64.toByteArray(auth["authorizationToken"]));
        let [username, password] = token.split(":", 2);

        // Make sure the password is masked in the logs.
        actions.setSecret(password);

        let ecr_image = account_id+".dkr.ecr."+region+".amazonaws.com/"+repository+":latest";

        await exec.exec("docker", ["login", "-u", username, "-p", password, auth["proxyEndpoint"]]);
        await exec.exec("docker", ["tag", image, ecr_image]);
        await exec.exec("docker", ["push", ecr_image]);
    } catch (e) {
        console.log("error: "+e);
        process.exit(1);
    }
};

main();
