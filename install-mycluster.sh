source ~/ansible/bin/activate
export INVENTORY_TO_USE=static && export CLOUD_TO_USE=static
#Comment
#ansible -i inventory/static all --list-hosts
#ansible -i inventory/static all -m setup
#!/usr/bin/env bash
bash prepare_nodes.sh
bash install_ambari.sh
bash configure_ambari.sh

export INVENTORY_TO_USE=kdcinventory && export CLOUD_TO_USE=static
bash install_kdc.sh

export INVENTORY_TO_USE=static && export CLOUD_TO_USE=static
bash apply_blueprint.sh
bash post_install.sh
