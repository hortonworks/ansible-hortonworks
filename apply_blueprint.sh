#!/usr/bin/env bash

source $(dirname "${BASH_SOURCE[0]}")/set_cloud.sh

ansible-playbook "playbooks/apply_blueprint.yml" \
                 --inventory="inventory/${cloud_to_use}" \
                 --extra-vars="cloud_name=${cloud_to_use}" \
                 "$@"
