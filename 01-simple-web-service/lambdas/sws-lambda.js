// Load the AWS SDK for Node.js
const AWS = require('aws-sdk');
// Set the region 
AWS.config.update({ region: 'us-east-1' });

exports.handler = function (event, context, callback) {
    const ddb = new AWS.DynamoDB({ apiVersion: '2012-08-10' });
    let body = JSON.parse(event.body);
    //console.log("EVENT: \n" + JSON.stringify(JSON.parse(event.body)));
    
    let params = {
        TableName: process.env.TableName,
        Item: {
            'GithubURL': { S: body.GithubURL },
            'Year': { N: body.Year }
        }
    };

    // Call DynamoDB to add the item to the table
    ddb.putItem(params, function (err, data) {
        if (err) {
            console.log("Error", err);
        } else {
            console.log("Success", data);
        }
    });
}