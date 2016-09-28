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
   pip install ansible "azure==2.0.0rc5" msrest msrestazure
   ```


1. Fix an Ansible bug affecting the azure library:

  ```
  sed -i s/result._task.loop_control.get\(\'loop_var\'\)/result._task.loop_control.loop_var/g ~/ansible/lib64/python2.7/site-packages/ansible/executor/process/result.py
  ```


1. Generate SSH public/private key pair if this node doesn't have one (press Enter for defaults):

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
   pip install ansible "azure==2.0.0rc5" msrest msrestazure
   ```


1. Fix an Ansible bug affecting the azure library:

  ```
  sed -i s/result._task.loop_control.get\(\'loop_var\'\)/result._task.loop_control.loop_var/g ~/ansible/lib/python2.7/site-packages/ansible/executor/process/result.py
  ```


1. Generate SSH public/private key pair if this node doesn't have one (press Enter for defaults):

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


## cloud_config
This section contains variables that are cluster specific and are used by all nodes:

| Variable        | Description                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| name_prefix     | A prefix that will precede the name of all nodes. Usually the cluster name to uniquely identify the nodes. |
| name_suffix     | A suffix that will be appended to the name of all nodes. Usually it's a domain, but can be anything or even the empty string `''`. |
| location        | The Azure Region as described [here](https://azure.microsoft.com/en-gb/regions/).                          |
| admin_username  | The Linux user with sudo permissions. Can be changed in Azure.                                             |
| ssh.privatekey  | Local path to the SSH private key that will be used to login into the nodes. This can be the key generated as part of the Build Setup, step 5. |
| ssh.publickey   | Local path to the SSH public key that will be placed on cluster nodes at build time.                                        |
| resource_group  | A container that holds related resources for an application. It will be created if it doesn't exist. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/resource-group-overview/). |
| storage_account | A namespace to store and access Azure Storage data objects. Must be an unique name across all Azure. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/storage-create-storage-account/). |
| network         | The Azure virtual network (VNet). It will be created if it doesn't exist. The address range can be customized. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-overview/). |
| subnet          | Subnet is a range of IP addresses in the VNet. It will be created if it doesn't exist. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-overview/#subnets). |
| security_groups | A list of Access Control List (ACL) associated with the subnet. Details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-networks-nsg/). |


## nodes config

This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

There can be any number of groups.

And groups can have any names and any number of nodes but they should correspond with the host groups in the Ambari Blueprint.


| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the Azure Resource Group. This is the reason why the default contains the `name_prefix`. Other groups can be added to correspond with the required architecture. |
| count           | The number of nodes to be built in this group. |
| image           | The OS image to be used. More details [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-linux-cli-ps-findimage/). |
| flavor          | The flavor / size of the node. A list of all the flavors can be found [here](https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-linux-sizes/) and the pricing [here](https://azure.microsoft.com/en-gb/pricing/details/virtual-machines/linux/#Windows). |
| public_ip       | If the VM should have a Public IP assigned to it. Required if the build node does not have access to the private IP range of the cluster nodes. |
| security_group  | The security group that should be applied to the node.                                                             |
| ambari_server   | Set it to `true` if the group also runs an Ambari Server. The number of nodes in this group should be 1. If there are more than 1 node, ambari-server will be installed on all of them, but only the first one (in alphabetical order) will be used by the Ambari Agents. |


# Build the Cloud environment

Run the script that will build the Cloud environment:

```
cd ~/ansible-hdp*/ && bash build_azure.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```


# Set the cluster variables

Modify the file at `~/ansible-hdp/playbooks/group_vars/all` to set the cluster configuration.

| Variable        | Description                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| ambari_version  | The Ambari version, in the full, 4-number form, for example: `2.4.1.0`. |


# Prepare the nodes

Run the script that will prepare the nodes for the Ambari installation:

```
cd ~/ansible-hdp*/ && bash prepare_nodes_azure.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```


# Install Ambari

Run the script that will install and configure Ambari Agents and Ambari Server:

```
cd ~/ansible-hdp*/ && bash install_ambari_azure.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```
