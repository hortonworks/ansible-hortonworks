#!/usr/bin/env bash

source $(dirname "${BASH_SOURCE[0]}")/set_cloud.sh

case $cloud_to_use in
aws|azure|gce|openstack)
  ;;
*)
  message="CLOUD_TO_USE environment variable was set to \"$CLOUD_TO_USE\" but must be set to one of the following: aws, azure, gce, openstack"
  echo -e $message
  exit 1
  ;;
esac

ansible-playbook --connection=local "playbooks/clouds/build_${cloud_to_use}.yml" "$@"
