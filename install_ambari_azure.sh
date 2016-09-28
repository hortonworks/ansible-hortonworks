#!/bin/bash

ansible-playbook -i inventory/azure -e "add_nodes_playbook=add_nodes_azure.yml" playbooks/install_ambari.yml
