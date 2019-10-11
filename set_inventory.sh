#!/usr/bin/env bash

if [ -z "$INVENTORY_TO_USE" ]; then
    echo -e "\e[94m[INFO]\e[0m - INVENTORY_TO_USE environment variable not set, defaulting to 'inventory/${cloud_to_use}'"
    echo -e "See 'https://github.com/hortonworks/ansible-hortonworks/blob/master/INSTALL_${cloud_to_use}.md' for more details"
    inventory_to_use="${cloud_to_use}"
else
    echo -e "\e[94m[INFO]\e[0m - INVENTORY_TO_USE environment variable set to '${INVENTORY_TO_USE}'"
    inventory_to_use="${INVENTORY_TO_USE}"
fi


