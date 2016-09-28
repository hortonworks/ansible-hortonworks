#!/bin/bash

ansible-playbook -i inventory/azure playbooks/prepare_nodes_azure.yml
