#!/bin/bash

# Install standard libraries, packages
setup_instance() {
  apt-get update
  get_ec2_metadata
  add_to_bashrc "gist_id" $gist_id
  add_keypair_to_profile
  add_multiverse
  apt-get update
  add_base_repositories
  apt-get update
  install_base_packages
  install_sun_java
  bugfixes
  sync_date
  increase_ulimits
  increase_max_memory
  increase_ssh_keepalive
  add_init_script_template $github_account_name
  install_node
  install_node_monitor
  configure_s3cmd
}