#!/bin/bash

ansible-playbook -i inventory/openstack -e "add_nodes_playbook=add_nodes_openstack.yml" playbooks/install_ambari.yml
