var walker = require('walker');

Bootstrap = function() {

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