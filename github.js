var rest = require('restler');
Github = function (username, password) {
  console.log('Github username: ' + username);
  console.log('Github password: ' + password);
  this.username = username;
  this.password = password;
};
Github.prototype.getGists = function (callback) {
  var url = 'https://' + this.username + ':' + this.password + '@api.github.com/users/' + this.username + '/gists';
  rest.get(url).on('complete', function (response) {
    response.forEach(function (gist) {
      console.log('ID: ' + gist.id); /* aws-bootstrap */
      console.log('Name: ' + gist.description);
    });
    callback(response);
  });
};
Github.prototype.getGistContent = function (id, callback) {
  var url = 'https://' + this.username + ':' + this.password + '@api.github.com/gists/' + id;
  rest.get(url).on('complete', function (response) {
    var scripts = {};
    for (var file in response.files) {
      scripts[file] = response.files[file].content;
    }
    callback(scripts);
  });
};
Github.prototype.addGist = function (description, public, files, callback) {
  var url = 'https://' + this.username + ':' + this.password + '@api.github.com/gists';
  var gist = {};
  gist['description'] = description;
  gist['public'] = public;
  gist['files'] = files;
  rest.post(url, {
    data: gist
  }).on('complete', function (response) {
    callback(response);
  });
};
exports.Github = Github;