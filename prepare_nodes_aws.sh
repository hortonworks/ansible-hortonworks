#!/bin/bash

ansible-playbook -i inventory/aws playbooks/prepare_nodes_aws.yml
