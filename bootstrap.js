var walker = require('walker'), 
  helper = require('./helper'), 
    constants = require('./constants');

Bootstrap = function(email, awsAccountId, awsKey, awsSecret, githubUsername, gihubPassword) {
  helper = new helper.Helper();
  if (!helper.validateEmail(email))
    helper.exit(constants.ERROR.VALIDATE_EMAIL);
  
  if (!helper.validateAwsCredentials(awsAccountId, awsKey, awsSecret))
    helper.exit(constants.ERROR.VALIDATE_AWS_CREDENTIALS);
  
  if (!helper.validateGithubCredentials(githubUsername, githubPassword))
    helper.exit(constants.ERROR.VALIDATE_GITHUB_CREDENTIALS);
};

Bootstrap.prototype.addGistsToGithub = function() {
  Walker('gists/').filterDir(function(dir, stat) {
    return true;
  })
  .on('file', function(file, stat) {
    console.log('Got file: ' + file);
  })
  .on('error', function(er, entry, stat) {
    console.log('Got error ' + er + ' on entry ' + entry);
  })
  .on('end', function() {
    console.log('All files traversed.');
  })
};

Bootstrap.prototype.createAMIInstances = function() {

};

exports.Bootstrap = Bootstrap;