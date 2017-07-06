#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/set_cloud.sh"

ansible-playbook -i "inventory/${cloud_to_use}" -e "cloud_name=${cloud_to_use}" playbooks/apply_blueprint.yml
