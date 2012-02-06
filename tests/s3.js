require('./setup');
var S3 = require('../s3');
s3 = new S3.S3();
s3.put('github.js', 'github.js');
//s3.get('github.js');
//s3.remove('github.js');