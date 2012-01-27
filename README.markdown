# aws-bootstrap

A scaling, monitored, distributed-ready, persistent infrastructure-creator.  Getting there shouldn't be the hard part.

## Giants

First and fore-most, I wouldn't have been able to create this without plenty of practice.

## Pre-reqs

AWS account 
Github account

### Dependencies

While you don't have to worry about these, it's good to know what went into the project.

* node-monitor, available here: 
* node-cloudwatch, available via npm
* ec2, available via npm

## ....Go

* Export your credentials from the command line:

From any unix machine: 

`curl https://frank.lovecch.io/labs/aws-bootstrap | aws-bootstrap`

### What it does

Creates Gists for versioned instance setups based on input credentials.
Spings up this with AWS user-data which pulls Gists.

Loadbalancer -> 2 Webservers/API -> MQdb (3 'Redis) cassandra.io
                        |
                        ^
     Socket.io <- Either of boxes -> Socket.io

Create alarms in CloudWatch to auto-scale webserver based on traffic.  

Backs-up to S3
