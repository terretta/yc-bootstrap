#!/bin/bash

# Add to the bash profile, also exports variables
# $1: variable name
# $2: variable value
add_to_bashrc() {
  export $1=$2
  echo -e "$1=$2" >> ~ubuntu/.bashrc
  echo -e "$1=$2" >> ~root/.bashrc
}

# Add executable path
# $1: path to executable
add_to_path() {
  export PATH=$PATH:$1
  echo -e "export PATH=$PATH:$1" >> ~ubuntu/.bashrc
  echo -e "export PATH=$PATH:$1" >> ~root/.bashrc
}

# Gets the EC2 metadata script for instance-specific info
get_ec2_metadata() {
  wget http://s3.amazonaws.com/ec2metadata/ec2-metadata
  chmod u+x ec2-metadata
}

# Adds SSH keypair to profile for AWS tool AMI creation
add_keypair_to_profile() {
  keypair=`cat ~ubuntu/.ssh/authorized_keys | awk '{print$3}'`
  add_to_bashrc "EC2_KEYPAIR" $keypair
}

# Adds multiverse repositories to /etc/apt/sources.list
add_multiverse() {
  echo -e "deb http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ oneiric multiverse" >> /etc/apt/sources.list
  echo -e "deb-src http://us-east-1.ec2.archive.ubuntu.com/ubuntu/ oneiric multiverse" >> /etc/apt/sources.list
}

# Adds all PPA repos
add_base_repositories() {
  yes | apt-add-repository ppa:ferramroberto/java
  yes | apt-add-repository ppa:awstools-dev/awstools 
}

# Install Sun Java
install_sun_java() {
  echo "sun-java6-jdk shared/accepted-sun-dlj-v1-1 boolean true" | sudo -E debconf-set-selections
  yes | apt-get install sun-java6-jdk sun-java6-plugin
  update-alternatives --set java /usr/lib/jvm/java-6-sun/jre/bin/java
  add_to_bashrc "JAVA_HOME" "/usr/lib/jvm/java-6-sun-1.6.0.26"
}

# All the base packages that we can't do without
install_base_packages() {
  yes | apt-get install openjdk-7-jre ec2-api-tools ec2-ami-tools s3cmd \
  libjna-java ant maven2 \
  git-core git git-svn \
  rubygems python curl unzip libssl-dev \
  build-essential libgtk2.0-0 libtool autoconf automake libpcre3-dev libgtk2.0-0 libtool gcc g++ scons pkg-config autoconf \
  sendmail mailutils ntp

  yes | apt-get install mdadm --no-install-recommends
}

# Cover all known issues
bugfixes() {
  bugfixes_jna
}

# Clone authenticated repositories
# $1: a repository name
git_repo() {
  git clone http://$github_username:$github_password@github.com/$github_account_name/$1.git
}

# Update a repo by specifying name
# $1: name
update_repo() {
  cd $1
  git pull
  cd ../
}

# Clone authenticated gists, remove directory
# $1: id
git_gist() {
  git clone https://$github_username:$github_password@github.com/gist/$1.git
  chmod a+x $1/*
  mv $1/* .
  rm -r $1
}

# Raid0, but we don't add md0 to fstab (/etc/init.d script should remount it). EC2 used to be sporadic about what drive names it assigned, regardless of specified command-line options.
# $1: mount point of raid 
# $2: init.d script to modify for re-mount
ephemeral_raid() {
  drive1=/dev/xvdb
  drive2=/dev/xvdc
  umount /mnt
  sed -i '$ d' /etc/fstab
  dd if=/dev/zero of=$drive1 bs=4096 count=1024
  dd if=/dev/zero of=$drive2 bs=4096 count=1024
  mdadm --create --verbose /dev/md0 --name=0 --chunk=256 --level=0 --raid-devices=2 $drive1 $drive2
  chmod 777 /etc/mdadm/mdadm.conf
  mdadm -Db /dev/md0 >> /etc/mdadm/mdadm.conf
  update-initramfs -u
  blockdev --setra 65536 /dev/md0
  mkfs -t ext3 /dev/md0
  mkdir -p /mnt/$1 && mount -t ext3 -o noatime /dev/md0 /mnt/$1
  add_init_command $2 "mount -t ext3 -o noatime /dev/md0 /mnt/$1"
}

# Add a basic init.d script which is run before upstart jobs
# $1: name
add_init_script_template() {
  file=/etc/init.d/$1
  echo -e "#!/bin/bash" >> $file
  echo -e "### BEGIN INIT INFO" >> $file
  echo -e "# Provides:		$1" >> $file
  echo -e "# Required-Start:" >> $file
  echo -e "# Required-Stop:" >> $file
  echo -e "# Default-Start:	2 3 4 5" >> $file
  echo -e "# Default-Stop:" >> $file		
  echo -e "# Short-Description:	$1" >> $file
  echo -e "### END INIT INFO" >> $file
  chmod a+x /etc/init.d/$1
  update-rc.d $1 defaults
  chmod 777 /etc/init.d/$1
}

# Generate self-signed certs
generate_ssl_certs() {
  openssl genrsa -out server.key 1024
  touch openssl.conf
  file=openssl.conf
  echo -e "[ req ]" >> $file
  echo -e "prompt = no" >> $file
  echo -e "distinguished_name = req_distinguished_name" >> $file
  echo -e "" >> $file
  echo -e "[ req_distinguished_name ]" >> $file
  echo -e "C = GB" >> $file
  echo -e "ST = Test State" >> $file
  echo -e "L = Test Locality" >> $file
  echo -e "O = Org Name" >> $file
  echo -e "OU = Org Unit Name" >> $file
  echo -e "CN = Common Name" >> $file
  echo -e "emailAddress = dev@email.com" >> $file
  openssl req -config openssl.conf -new -key server.key -out server.csr
  openssl x509 -req -days 1024 -in server.csr -signkey server.key -out server.crt
}

# Add a command to the init script
# $1: name
# $2: command
add_init_command() {
  echo -e "$2" >> /etc/init.d/$1
}

# Add a simple upstart job
# $1: job/dir/file name
# $2: command(s) to be run as root
add_upstart_job() {
  touch /var/log/$1.log
  chmod 777 /var/log/$1.log
  file=/etc/init/$1.conf
  echo -e "description \"$1\"" >> $file
  echo -e "start on (local-filesystems and net-device-up IFACE=eth0)" >> $file
  echo -e "stop on shutdown" >> $file
  echo -e "exec sudo -u root sh -c \"$2 >> /var/log/$1.log 2>&1 &"\" >> $file    
}

# Replace one string with another in file
# $1: string to replace
# $2: replacement string
# $3: absolute path of file to modify
sed_replace() {
  sed -i "s/$1/$2/g" $3
}

# JNA hangs without this
bugfixes_jna() {
  rm /usr/share/java/jna.jar
}

# Keep the clock straight
sync_date() {
  chmod 777 /etc/cron.daily
  echo -e "ntpdate ntp.ubuntu.com" > /etc/cron.daily/ntpdate
}

# Adds a cronjob to run as root
# $1: cronjob declaration -- 30 5 * * * <script>
add_cronjob() {
  crontab -l | (cat; echo "30 5 * * * $1") | crontab
}

# Max out the ulimits
increase_ulimits() {
  file=/etc/security/limits.conf
  echo -e "*		 soft	 nofile     131072" >> $file
  echo -e "*		 hard	 nofile     131072" >> $file
  echo -e "root	 soft	 nofile     131072" >> $file
  echo -e "root	 hard	 nofile     131072" >> $file
}

# Max out the mem
increase_max_memory() {
  sysctl -w net.core.rmem_max=4194304
  sysctl -w net.core.wmem_max=4194304
}

# Increase SSH timeout
increase_ssh_keepalive() {
  chmod 777 /etc/ssh/sshd_config
  echo -e "ClientAliveInterval 300" >> /etc/ssh/sshd_config
  service ssh restart
}

# Grap the AWS internal IP for localhost
get_internal_ip() {
  IP=`ifconfig | grep -v grep | awk 'NR==2{print $2}'`
  INTERNAL_IP=$(echo $IP|sed 's/addr://g')
}

# Configure AWS S3 command line utility
configure_s3cmd() {
  file_one=~root/.s3cfg
  file_two=~ubuntu/.s3cfg
  echo -e "[default]" >> $file_one >> $file_two
  echo -e "access_key = $amazon_key" >> $file_one >> $file_two
  echo -e "bucket_location = US" >> $file_one >> $file_two
  echo -e "cloudfront_host = cloudfront.amazonaws.com" >> $file_one >> $file_two
  echo -e "cloudfront_resource = /2010-07-15/distribution" >> $file_one >> $file_two
  echo -e "default_mime_type = binary/octet-stream" >> $file_one >> $file_two
  echo -e "delete_removed = False" >> $file_one >> $file_two
  echo -e "dry_run = False" >> $file_one >> $file_two
  echo -e "encoding = UTF-8" >> $file_one >> $file_two
  echo -e "encrypt = False" >> $file_one >> $file_two
  echo -e "follow_symlinks = False" >> $file_one >> $file_two
  echo -e "force = False" >> $file_one >> $file_two
  echo -e "get_continue = False" >> $file_one >> $file_two
  echo -e "gpg_command = /usr/bin/gpg" >> $file_one >> $file_two
  echo -e "gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s" >> $file_one >> $file_two
  echo -e "gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s" >> $file_one >> $file_two
  echo -e "gpg_passphrase = $passphrase" >> $file_one >> $file_two
  echo -e "guess_mime_type = True" >> $file_one >> $file_two
  echo -e "host_base = s3.amazonaws.com" >> $file_one >> $file_two
  echo -e "host_bucket = %(bucket)s.s3.amazonaws.com" >> $file_one >> $file_two
  echo -e "human_readable_sizes = False" >> $file_one >> $file_two
  echo -e "list_md5 = False" >> $file_one >> $file_two
  echo -e "log_target_prefix =" >> $file_one >> $file_two
  echo -e "preserve_attrs = True" >> $file_one >> $file_two
  echo -e "progress_meter = True" >> $file_one >> $file_two
  echo -e "proxy_host =" >> $file_one >> $file_two
  echo -e "proxy_port = 0" >> $file_one >> $file_two
  echo -e "recursive = False" >> $file_one >> $file_two
  echo -e "recv_chunk = 4096" >> $file_one >> $file_two
  echo -e "reduced_redundancy = False" >> $file_one >> $file_two
  echo -e "secret_key = $amazon_secret" >> $file_one >> $file_two
  echo -e "send_chunk = 4096" >> $file_one >> $file_two
  echo -e "simpledb_host = sdb.amazonaws.com" >> $file_one >> $file_two
  echo -e "skip_existing = False" >> $file_one >> $file_two
  echo -e "urlencoding_mode = normal" >> $file_one >> $file_two
  echo -e "use_https = True" >> $file_one >> $file_two
  echo -e "verbosity = WARNING" >> $file_one >> $file_two
}

# Install the Nexus Maven Repository
install_nexus() {
  wget http://nexus.sonatype.org/downloads/nexus-oss-webapp-1.9.2.4-bundle.tar.gz
  tar xzf nexus-oss-webapp-1.9.2.4-bundle.tar.gz 
  rm nexus-oss-webapp-1.9.2.4-bundle.tar.gz 
}

# Install Redis
install_redis() {
  wget http://redis.googlecode.com/files/redis-2.4.5.tar.gz
  tar xzf redis-2.4.5.tar.gz
  rm redis-2.4.5.tar.gz
  cd redis-2.4.5
  make
  cd ../
}

# Install Sinatra
install_sinatra() {
  gem install rubygems-update
  update_rubygems
  gem install sinatra redis json builder twilio-ruby
  gem install sinatra-redis -s http://gemcutter.org 
}

# Install Node.js
install_node() {
  wget http://nodejs.org/dist/v0.6.6/node-v0.6.6.tar.gz
  tar -xzf node-v0.6.6.tar.gz
  rm node-v0.6.6.tar.gz
  cd node-v0.6.6
  ./configure
  make
  make install
  export PATH=$PATH:/opt/node/bin
  curl http://npmjs.org/install.sh | sudo sh
  cd ../
}

# Install node-monitor
# $1: dev/prod what namespace to push metrics to
install_node_monitor() {
  git_repo node-monitor
  mkdir .node-monitor
  cd node-monitor/bin
  wget http://s3.amazonaws.com/ec2metadata/ec2-metadata
  chmod a+x ec2-metadata
  cd ../
  npm link
  cd ../
  cp node-monitor/bin/node-monitor.sh node-monitor.sh
  chmod a+x node-monitor.sh
  add_upstart_job node-monitor "cd /home/ubuntu/node-monitor/run && /usr/local/bin/node client.js ec2=true debug=false console=true cloudwatch=true" false
  file=node-monitor/config/monitor_config
  echo -e "" > $file
  echo -e "plugin_poll_time=300" >> $file
  if [ "$1" == "dev" ]; then
    echo -e "cloudwatch_namespace=$cloudwatch_dev_namespace" >> $file
  else 
    echo -e "cloudwatch_namespace=$cloudwatch_prod_namespace" >> $file
  fi
  echo -e "AWS_ACCESS_KEY_ID=$amazon_key" >> $file
  echo -e "AWS_SECRET_ACCESS_KEY=$amazon_secret" >> $file
  file=node-monitor/plugins/filesize_config
  echo -e "/var/log/node-monitor.log=200000" >> $file
}

# node-monitor - aid in monitoring new file
# $1: disk to monitor
monitor_new_disk() {
  echo -e "$1" >> /home/ubuntu/node-monitor/plugins/df_config
}

# node-monitor - aid in monitoring new service
# $1: service, or service/port to monitor
monitor_new_service() {
  echo -e "$1" >> /home/ubuntu/node-monitor/plugins/services_config
}

# node-monitor - aid in monitoring keyspaces
# $1: directory
monitor_keyspace_directory() {
  echo -e "$1" >> /home/ubuntu/node-monitor/plugins/keyspaces_config
}

# node-monitor - aid in monitoring new file
# $1: file/size to monitor
monitor_new_file() {
  echo -e "$1" >> /home/ubuntu/node-monitor/plugins/filesize_config
}

# Install the realtime bridge
install_zmq_socketio_bridge() {
  git_repo zmq-socketio-bridge
  cd zmq-socketio-bridge
  npm link
  cd ../
}

# Install Express
install_express() {
  npm install -g express
  cd /usr/local/lib/node_modules/express
  npm install -d
  cd /home/ubuntu
}

# Install Java ZMQ binding
install_jzmq() {
  apt-get install openjdk-7-jre
  git clone https://github.com/zeromq/jzmq.git
  cd /home/ubuntu/jzmq/
  ./configure
  make
  make install
  mvn install -DskipTests
  cd ../
}

# Install Play! Framework
install_play_framework() {
  wget http://download.playframework.org/releases/play-1.2.4.zip
  unzip play-1.2.4.zip
  rm play-1.2.4.zip
  current_directory=`pwd`
  export PATH=$PATH:$current_directory/play-1.2.4
  echo -e "export PATH=$PATH:$current_directory/play-1.2.4" >> ~ubuntu/.bashrc
  echo -e "export PATH=$PATH:$current_directory/play-1.2.4" >> ~root/.bashrc
}

# Install Mavenized Play! applications
# $1: path to app
install_play_framework_app() {
  play deps $1 --sync
  play deps $1
  cp jzmq/target/jzmq-1.0.0.jar $1/lib/
}

# Build an AWS AMI 
# $1: name
build_ami() {
  size=`/home/ubuntu/ec2-metadata | grep -v grep | grep "instance-type" | awk '{print$2}'`
  ami=`echo $1 | tr '[A-Z]' '[a-z]'`
  mkdir /mnt/$ami
  history -c
  if [ "$size" == "m1.large" ]; then
    ec2-bundle-vol -d /mnt/$ami -k $path_to_aws_keypair -c $path_to_aws_cert -u $amazon_account_id -r x86_64
  else
    ec2-bundle-vol -d /mnt/$ami -k $path_to_aws_keypair -c $path_to_aws_cert -u $amazon_account_id -r i386
  fi
  ec2-upload-bundle -b $ami -m /mnt/$ami/image.manifest.xml -a $amazon_key -s $amazon_secret
  ec2-register $ami/image.manifest.xml -K $path_to_aws_keypair -C $path_to_aws_cert
  email "AMI Bundling completed: $ami" "For AMI $ami with IP $INTERAL_IP" $email_address
}