# yc-bootstrap

A scaling, monitored, distributed-ready, realtime, persistent infrastructure-creator.  Take control over your IAAS.

## Giants

First and fore-most, I've perfected this from m2m.io environment setup.

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

Create alarms in CloudWatch to auto-scale webserver based on traffic.  Uses hummingbird. Comet as backup.

Backs-up to S3

### Process flow
When you bootstrap, we initially push all the scripts in `gists/` to your Github account under the name `aws-bootstrap`.
Next, we create AMIs for your webserver, api, distributed cache, and realtime instances by using the Gists as user-data.  
When the AMIs are finished, we'll launch the instances via CloudWatch and create all the alarms to auto-scale the webserver and api.
