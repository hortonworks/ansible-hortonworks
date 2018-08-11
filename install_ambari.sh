#!/usr/bin/env bash

source $(dirname "${BASH_SOURCE[0]}")/set_cloud.sh

ansible-playbook -i "inventory/${cloud_to_use}" -e "cloud_name=${cloud_to_use}" playbooks/install_ambari.yml "$@"
