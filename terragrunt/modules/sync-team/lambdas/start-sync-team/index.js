const AWS = require('aws-sdk');
const CodeBuild = new AWS.CodeBuild();

exports.handler = async function(event) {
    return CodeBuild.startBuild({
        projectName: 'sync-team',
    }).promise();
};
