var fs = require('fs'), github = require('../github');
github = new github.Github('<>', '<>');
/*
github.getGists(function(response) { 
  console.log('Response: ' + JSON.stringify(response)); 
});
*/
var id = '<id>';
/*
github.getGistContent(id, function(response) { 
  for (var file in response) {
    console.log('Script: ' + file);
    console.log('Content: ' + response[file]);
  }
});
*/
fs.readFile('../gists/base_setup.sh', function (error, fd) {
  if (error)
    console.log('Error reading file');

  console.log('Read file: ' + fd.toString());
});
/*
github.addGistContent(id, function (response) {
  for (var file in response) {
    console.log('Script: ' + file);
    console.log('Content: ' + response[file]);
  }
});
*/