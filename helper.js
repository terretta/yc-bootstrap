Helper = function () {

};
Helper.prototype.validateEmail = function () {
 
};
Helper.prototype.validateAwsCredentials = function () {
 
};
Helper.prototype.validateGithubCredentials = function () {

};
Helper.prototype.removeEmptyLinesFromGists = function(file) {
  var str = file.value;
  while(str.indexOf("\r\n\r\n") >= 0) {
    str = str.replace(/\r\n\r\n/g, "\r\n")      
  }
  file.value = str;
};
Helper.prototype.exit = function () {
 
};
exports.Helper = Helper;