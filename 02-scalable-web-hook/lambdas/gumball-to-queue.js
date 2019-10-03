
const AWS = require('aws-sdk');


exports.handler = function (event) {
    const body = event.body;
    const accountId = process.env.accountId;
    const queueName = process.env.queueName;
    const region = process.env.region;
//const colors = ['red', 'blue', 'green', 'black', 'purple', 'yellow']
//const color = body.color === 'random' ? colors[Math.floor(Math.random() * colors.length)] : color;
    const color = body.color;

AWS.config.update({ region: region });
const sqs = new AWS.SQS({ apiVersion: '2012-11-05' });

const params = {
    MessageBody: JSON.stringify({
        color: body.color,
        date: (new Date()).toISOString()
    }),
    QueueUrl: `https://sqs.${region}.amazonaws.com/${accountId}/${queueName}`
};


    sqs.sendMessage(params, (err, data) => {
        if (err) {
            console.log("Gumball NOT to queue :(", err);
        } else {
            console.log("Gumball to Queue", data.MessageId);
        }
    });
}
