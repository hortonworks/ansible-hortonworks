ansible-hdp installation guide
------------------------------

* These Ansible playbooks can build a Cloud environment in Azure.

---


# Build setup

Before building anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH and to the Azure APIs via HTTPS.


## CentOS/RHEL 7

1. Install the required packages

  ```
  sudo yum -y install epel-release || sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sudo yum -y install gcc gcc-c++ python-virtualenv python-pip python-devel libffi-devel openssl-devel sshpass git vim-enhanced
  ```


1. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate 
   ```


1. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade   
   pip install pycparser===2.13 ansible "azure==2.0.0rc5" msrest msrestazure
   ```


1. Fix an Ansible bug affecting the azure library:

  ```
  sed -i s/result._task.loop_control.get\(\'loop_var\'\)/result._task.loop_control.loop_var/g ~/ansible/lib64/python2.7/site-packages/ansible/executor/process/result.py
  ```


1. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists):

  ```
  ssh-keygen -q -t rsa
  ```


## Ubuntu 16+

1. Install required packages:

  ```
  sudo apt-get update
  sudo apt-get -y install unzip python-virtualenv python-pip python-dev sshpass git libffi-dev libssl-dev vim
  ```


1. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate  
   ```


1. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade
   pip install pycparser===2.13 ansible "azure==2.0.0rc5" msrest msrestazure
   ```


1. Fix an Ansible bug affecting the azure library:

  ```
  sed -i s/result._task.loop_control.get\(\'loop_var\'\)/result._task.loop_control.loop_var/g ~/ansible/lib/python2.7/site-packages/ansible/executor/process/result.py
  ```


1. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists):

  ```
  ssh-keygen -q -t rsa
  ```


# Setup the Azure credentials file

1. Create a service principal

  Use the following [guide](https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal) to create a Service Principal.

  After the tutorial the following should have been obtained:

    * Subscription ID (from the Subscription page in the Azure portal)
    * Client ID
    * Secret key (generated when the application was created)
    * Tenant ID


1. Create the credentials file

  Store the obtained credentials in a file and save this file as `.azure/credentials` under the home folder of the user running the playbook.

  ```
  [default]
  subscription_id=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  client_id=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  secret=xxxxxxxxxxxxxxxxx
  tenant=xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  ```
  
  
  ```
  mkdir -p ~/.azure/
  cat > ~/.azure/credentials
  ```


# Clone the repository

Upload the ansible-hdp repository to the build node / workstation, preferable under the home folder.

If the build node / workstation can directly download the repository, run the following:

```
cd && git clone https://github.com/hortonworks/ansible-hdp.git
```

If your GitHub SSH key is installed, you can use the SSH link:

```
cd && git clone git@github.com:hortonworks/ansible-hdp.git
```


# Set the Azure variables

Modify the file at `~/ansible-hdp/inventory/azure/group_vars/all` to set the Azure configuration.

## name_prefix
A helper variable that can be used to precede the name of the nodes nodes and other cluster specific Azure resources (such as the subnet or NICs).

Node names are derived from the group name (more details about groups bellow) and this variable can be used to uniquely identify a certain cluster, especially if the Resource Group is shared.


## cloud_config
This section contains variables that are cluster specific and are used by all nodes:

| Variable        | Description                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| name_suffix     | A suffix that will be appended to the name of all nodes. Usually it's a domain, but can be anything or even the empty string `''`. |
| location        | The Azure Region as described [here](https://azure.microsoft.com/en-gb/regions/).                          |
| admin_username  | The Linux user with sudo permissions. Can be customized in Azure as it's used when building the nodes.     |
| ssh.privatekey  | Local path to the SSH private key that will be used to login into the nodes. This can be the key generated as part of the Build Setup, step 5. |
| ssh.publickey   | Local path to the SSH public key that will be placed on cluster nodes at build time.                                        |
| resource_group  | A container that holds related resources for an application. It will be created if it doesn't exist. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/). |
| storage_account | A namespace to store and access Azure Storage data objects. It will be created if it doesn't exist. Must be an unique name across all Azure. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/storage-create-storage-account/). |
| network         | The Azure virtual network (VNet). It will be created if it doesn't exist. The address range can be customized. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-overview/). |
| subnet          | Subnet is a range of IP addresses in the VNet previously set. By default it uses the `name_prefix` in the name as the subnet should be dedicated to only one cluster. It will be created if it doesn't exist. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-overview/#subnets). |
| security_groups | A list of Access Control List (ACL) associated with the subnet. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-nsg/). |


## nodes config

This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

There can be any number of groups so other groups can be added to correspond with the required architecture.

And groups can have any name and any number of nodes but group names should correspond with the host groups in the Ambari Blueprint.

| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the Azure Resource Group so this is the reason why the default contains the `name_prefix`. It's used to derive the nodes names (if node count is greater than 1, numbers will be appended to the group name to uniquely identify nodes). |
| count           | The number of nodes to be built in this group. |
| image           | The OS image to be used. More details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-linux-cli-ps-findimage/). |
| flavor          | The flavor / size of the node. A list of all the flavors can be found [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-linux-sizes/) and the pricing [here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/#Windows). |
| public_ip       | If the VM should have a Public IP assigned to it. Required if the build node does not have access to the private IP range of the cluster nodes. |
| security_group  | The security group that should be applied to the node.                                                             |
| ambari_server   | Set it to `true` if the group also runs an Ambari Server. The number of nodes in this group should be 1. If there are more than 1 node, ambari-server will be installed on all of them, but only the first one (in alphabetical order) will be used by the Ambari Agents. |


# Build the Cloud environment

Run the script that will build the Cloud environment.

Set first the `CLOUD_TO_USE` environment variable to `azure`.

```
export CLOUD_TO_USE=azure
cd ~/ansible-hdp*/ && bash build_cloud.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```


# Set the cluster variables

## all config

Modify the file at `~/ansible-hdp/playbooks/group_vars/all` to set the cluster configuration.

| Variable          | Description                                                                                                |
| ----------------- | ---------------------------------------------------------------------------------------------------------- |
| ambari_version    | The Ambari version, in the full, 4-number form, for example: `2.4.1.0`.                                    |
| hdp_major_version | The HDP version, in the major, 2-number form, for example: `2.5`.                                          |
| cluster_name      | The name of the HDP cluster.                                                                               |


## ambari-server config

Modify the file at `~/ansible-hdp/playbooks/group_vars/ambari-server` to set the Ambari Server specific configuration.

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ambari_admin_user              | The Ambari admin username, normally `admin`.                                                               |
| ambari_admin_password          | The Ambari password of the `ambari_admin_user` user previously set.                                        |
| wait / wait_timeout            | Set this to `true` if you want the playbook to wait for the cluster to be successfully built after applying the blueprint. The timeout setting controls for how long (in seconds) should it wait for the cluster build. |
| blueprint_name                 | The name of the blueprint as it will be stored in Ambari.                                                  |
| blueprint_file                 | The path to the blueprint file that will be uploaded to Ambari. It can be an absolute path or relative to the `roles/ambari-blueprint/templates`  folder. It can also contain [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) variables. |
| cluster_template_file          | The path to the cluster creation template file that will be used to build the cluster. It can be an absolute path or relative to the `ambari-blueprint/templates`  folder. The default should be sufficient for cloud builds as it uses the `cloud_config` variables and [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) to generate the file. |
| default_password               | A default password for all required passwords which are not specified in the blueprint.                                                                               |
| config_recommendation_strategy | Configuration field which specifies the strategy of applying configuration recommendations to a cluster as explained in the [documentation](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure). |


# Install the HDP cluster

Run the script that will install the HDP cluster using Blueprints while taking care of the necessary prerequisites.

Make sure you set the `CLOUD_TO_USE` environment variable to `azure`.

```
export CLOUD_TO_USE=azure
cd ~/ansible-hdp*/ && bash install_hdp.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```


This script will apply all the required playbooks in one run, but you can also apply the individual playbooks by running the following wrapper scripts:

- Prepare the nodes: `prepare_nodes.sh`
- Install Ambari: `install_ambari.sh`
- Apply Blueprint: `apply_blueprint.sh`
