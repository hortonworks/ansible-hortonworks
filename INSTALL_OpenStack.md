ansible-hdp installation guide
------------------------------

* These Ansible playbooks can build a Cloud environment in a private OpenStack.

---


# Build setup

Before building anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH and to the OpenStack APIs via HTTPS.

As OpenStack environments are usually private, you might need to build such a node in the OpenStack environment.


## CentOS/RHEL 7

1. Install the required packages

  ```
  sudo yum -y install epel-release || sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  sudo yum install gcc gcc-c++ python-virtualenv python-pip python-devel libffi-devel openssl-devel libyaml-devel sshpass git vim-enhanced -y
  ```


1. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate 
   ```


1. Install the required Python inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade   
   pip install functools32 pytz ansible shade
   ```


1. Turn off SSL validation (required if your OpenStack endpoints don't use trusted certs)
  
  ```
  sed -i '/{$/a "verify": false,' ~/ansible/lib64/python2.7/site-packages/os_client_config/defaults.json
  ```


1. Install the SSH private key

  The build node / workstation will need to login via SSH to the cluster nodes.
  
  For this to succeed, the SSH private key needs to be downloaded from the OpenStack Dashboard (usually found on `Compute` -> `Access and Security` under the `Key Pairs` tab).
  
  Then it needs to be placed on the build node / workstation, normally under .ssh, for example: `~/.ssh/field.pem`.


## Ubuntu 14+

1. Install required packages:

  ```
  sudo apt-get update
  sudo apt-get -y install unzip python-virtualenv python-pip python-dev sshpass git libffi-dev libssl-dev libyaml-dev vim
  ```


1. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate  
   ```


1. Install the required Python inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade
   pip install functools32 pytz ansible shade
   ```


1. Turn off SSL validation (required if your OpenStack endpoints don't use trusted certs)
  
  ```
  sed -i '/{$/a "verify": false,' ~/ansible/local/lib/python2.7/site-packages/os_client_config/defaults.json
  ```


1. Install the SSH private key

  The build node / workstation will need to login via SSH to the cluster nodes.
  
  For this to succeed, the SSH private key needs to be downloaded from the OpenStack Dashboard (usually found on `Compute` -> `Access and Security` under the `Key Pairs` tab).
  
  Then it needs to be placed on the build node / workstation, normally under .ssh, for example: `~/.ssh/field.pem`.


# Setup the OpenStack credentials

1. Download the OpenStack RC file

  Login to your OpenStack dashboard, and download your user specific OpenStack RC file.
  This is usually found on `Compute` -> `Access and Security` under the `API Access` tab. Download the v3 if available.


1. Apply the OpenStack credentials

  Copy the file to the build node / workstation in a private location (for example the user's home folder).

  And `source` the file so it populates the existing session with the OpenStack environment variables.
  Type your OpenStack account password when prompted.

  ```
  source ~/ansible/bin/activate
  source ~/*-openrc.sh
  Please enter your OpenStack Password: 
  ```

  You can verify if it worked by trying to list the existing OpenStack instances:
  ```
  nova --insecure list
  ```


# Clone the repository

On the same build node / workstation, run the following or manually download the repository and upload it (especially if it's private):

```
cd && git clone https://github.com/hortonworks/ansible-hdp.git
```

If your GitHub SSH key is installed, you can use the SSH link:

```
cd && git clone git@github.com:hortonworks/ansible-hdp.git
```


# Set the OpenStack variables

Modify the file at `~/ansible-hdp/inventory/openstack/group_vars/all` to set the OpenStack configuration.


## cloud_config
This section contains variables that are cluster specific and are used by all nodes:

| Variable        | Description                                                                                                |
| --------------- | ---------------------------------------------------------------------------------------------------------- |
| hostname_prefix | A prefix that will precede the name of all nodes. Usually the cluster name to uniquely identify the nodes. |
| domain          | A suffix that will be appended to the name of all nodes. Usually it's a domain, but can be anything or even the empty string `''`. |
| zone            | The name of the OpenStack zone.                         |
| admin_username  | The Linux user with sudo permissions. This user is specific to the image used. For example, in a CentOS image, it can be `centos` or in a Ubuntu image it can be `ubuntu`. |
| ssh.keyname     | The name of the SSH key that will be placed on cluster nodes at build time. This SSH key must already exist in the OpenStack environment. |
| ssh.privatekey  | Local path to the SSH private key that will be used to login into the nodes. This is the key downloaded as part of the Build Setup, step 5. |


## nodes config

This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

Groups can have any names and any number of nodes and they should correspond with the host groups in the Ambari Blueprint.


| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the OpenStack Zone hence the default contains the `hostname_prefix`. Other groups can be added to correspond with the required architecture. |
| count           | The number of nodes to be built in this group. |
| image           | The OS image to be used. A list of the available images can be found by running `nova --insecure image-list`. |
| flavor          | The flavor / size of the node. A list of all the available flavors can be found by running `nova --insecure flavor-list`. |                                                      |
| public_ip       | If the Public IP of the cluster node should be used when connecting to it. Required if the build node does not have access to the private IP range of the cluster nodes. |


# Build the Cloud environment

Run the script that will build the Cloud environment:

```
cd ~/ansible-hdp*/ && bash build_openstack.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
source ~/*-openrc.sh
```
