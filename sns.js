var constantvar aws = require('node-aws').createClient('yourAccessKeyId', 'yourSecretAccessKey');
SNS = function () {

};
SNS.prototype.createTopics = function () {
  aws.sns.createTopic({
    domainName: "test",
    itemName: "alarm",
    attributes: [{
      name: 'Name',
      value: 'alarm',
    }, ],
  }).onSuccess(function () {
    // it worked!
    console.log(this.requestId, this.data);
  }).onFailure(function () {
    // uh oh!
    console.log(this.requestId, this.error);
  });
};
SNS.prototype.listTopics = function () {};
SNS.prototype.listSubscriptions = function () {};
SNS.prototype.subscribe = function () {};
SNS.prototype.confirmSubscriptions = function () {};