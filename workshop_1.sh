#!/usr/bin/env bash

## Variables
_srcDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $_srcDir
. `pwd`/variables/workshop1_variables

## Methods
. `pwd`/methods/workshop1/ec2/_key-pair
. `pwd`/methods/workshop1/ec2/_security-group
. `pwd`/methods/workshop1/ec2/_instances
. `pwd`/methods/workshop1/elb/_elb
. `pwd`/methods/workshop1/autoscaler/_autoscaler
. `pwd`/methods/workshop1/misc/_apache

### Script Begin ###
function f_deploy(){
  ##  Part 1: Deploying an Amazon EC2 Instance  ##
  # This will create or replace a key pair to be used for ssh
  echo -e "\t\tCreating a key pair..."
  f_test_key_pair

  # This will create an ec2 security group used for accessing services (SSH, HTTP)
  echo -e "\t\tCreating secruity group and adding ports..."
  f_create_security_group
  f_allow_ports

  # This will create an ec2 instance
  echo -e "\t\tCreating instance..."
  f_run_instances
  echo -e "\t\t\tWaiting for instance..."
  f_wait_for_instance_state "running"

  ##  Part 2: Configuring Apache and Creating a Web Page  ##
  # This will install and enable apache with a generic index.html
  echo -e "\t\t\tWaiting for SSH access..."
  f_wait_for_ssh
  echo -e "\t\tConfiguring Apache on instance..."
  f_yum_install_httpd
  f_create_index_html
  f_enable_start_httpd

  ##  Part 3: Create an Amazon Machine Image (AMI)  ##
  # This will create an Amazon Machine Image (AMI) for use with an ELB
  echo -e "\t\tCreating AMI..."
  f_create_image
  echo -e "\t\t\tWaiting for AMI creation..."
  f_wait_for_image

  ##  Part 4: Create an Elastic Load Balancer  ##
  # This will create an ELB to front our webserver
  echo -e "\t\tCreating ELB..."
  f_create_elb


  echo -e "\t\tCreating Autoscaler..."
  echo -e "\t\t\tCreating Autoscaler launch configuration..."
  f_create_autoscaler_config
  echo -e "\t\t\tCreating Autoscaler group..."
  f_create_autoscaler_group
}

function f_cleanup(){
  # The following steps will restore back to a clean environment
  echo -e "\t\tDeleting key pair..."
  f_delete_key_pair
  echo -e "\t\tTerminating instances..."
  f_terminate_instances
  echo -e "\t\t\tWaiting for instances to terminate..."
  f_verify_instance_terminated
  echo -e "\t\tDeregister AMI..."
  f_deregister_image
  echo -e "\t\t\tDeleting AMI snapshot..."
  #delete snapshot
  echo -e "\t\tDeleting ELB..."
  f_delete_elb
  echo -e "\t\tDeleting Autoscaler..."
  f_delete_autoscaler
  echo -e "\t\tDeleting secutiry group..."
  f_delete_security_group
  rm -f `pwd`/cache/ws1_*
}

function f_print_help(){
  echo -e "\n\tUsage: `pwd`/`basename \"$0\"` [ --deploy | --cleanup ]\n"
}
while true; do
  case $1 in
    --deploy* )
      echo -e "\n\tDeploying Workshop 1 environment...\n"
      echo -e "\t\tThis might take a few minutes, go grab a cofee.\n"
      f_deploy
      break
      ;;
    --cleanup* )
      echo -e "\n\tTearing down Workshop 1 environment...\n"
      f_cleanup
      break
      ;;
    * )
      f_print_help
      break
      ;;
  esac
done
### Script End ###

## References ##
# http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-launch-instance.html
# http://docs.aws.amazon.com/cli/latest/reference/ec2/create-security-group.html
