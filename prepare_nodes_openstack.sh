#!/bin/bash

ansible-playbook -i inventory/openstack playbooks/prepare_nodes_openstack.yml
