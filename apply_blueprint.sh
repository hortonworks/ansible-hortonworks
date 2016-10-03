#!/bin/bash

if [ -z "$CLOUD_TO_USE" ]; then
    echo "CLOUD_TO_USE environment variable must be set to one of the following: aws, azure, openstack"
    exit 1
fi

cloud_to_use=$(echo "$CLOUD_TO_USE" | tr '[:upper:]' '[:lower:]')
case $cloud_to_use in
aws)
  message="Cloud to be used is AWS.\nMake sure you've set the AWS authentication variables."
  ;;
azure)
  message="Cloud to be used is Microsoft Azure.\nMake sure $HOME/.azure/credentials exists and it's correct."
  ;;
openstack)
  message="Cloud to be used is OpenStack.\nMake sure you've sourced the OpenStack RC file."
  ;;
*)
  message="CLOUD_TO_USE environment variable was set to \"$CLOUD_TO_USE\" but must be set to one of the following: aws, azure, openstack"
  echo -e $message
  exit 1
  ;;
esac

echo -e $message
ansible-playbook -i inventory/$cloud_to_use -e "cloud_name=$cloud_to_use" playbooks/apply_blueprint.yml
