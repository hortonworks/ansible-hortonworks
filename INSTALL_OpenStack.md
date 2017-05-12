ansible-hdp installation guide
------------------------------

* These Ansible playbooks will build a Cloud environment on a private OpenStack.
* And then deploy a Hortonworks cluster (either Hortonworks Data Platform or Hortonworks DataFlow) using Ambari Blueprints.

---


# Build setup

Before building anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH and to the OpenStack APIs via HTTPS.

As OpenStack environments are usually private, you might need to build such a node in the OpenStack environment.


## CentOS/RHEL 7

1. Install the required packages

   ```
   sudo yum -y install epel-release || sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   sudo yum -y install gcc gcc-c++ python-virtualenv python-pip python-devel libffi-devel openssl-devel libyaml-devel sshpass git vim-enhanced
   ```


2. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate 
   ```


3. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade   
   pip install pycparser functools32 pytz ansible shade
   ```


4. Turn off SSL validation (required if your OpenStack endpoints don't use trusted certs)
  
   ```
   defaults_json_path=~/ansible/lib64/python2.7/site-packages/os_client_config/defaults.json; grep -q verify $defaults_json_path || sed -i '/{$/a "verify": false,' $defaults_json_path
   ```


5. Install the SSH private key

   The build node / workstation will need to login via SSH to the cluster nodes.
   
   For this to succeed, the SSH private key needs to be placed on the build node / workstation, normally under .ssh, for example: `~/.ssh/field.pem`. It can be placed under any path as this file will be referenced later.
   
   It should have `400` permissions: `chmod 0400 ~/.ssh/field.pem`.
   
   The SSH public key must be present on the OpenStack environment as it will be referenced when the nodes will be built (this can be checked on the Dashboard, under `Compute` -> `Access and Security` -> `Key Pairs` tab).


## Ubuntu 14+

1. Install required packages:

   ```
   sudo apt-get update
   sudo apt-get -y install unzip python-virtualenv python-pip python-dev sshpass git libffi-dev libssl-dev libyaml-dev vim
   ```


2. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate  
   ```


3. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade
   pip install pycparser functools32 pytz ansible shade
   ```


4. Turn off SSL validation (required if your OpenStack endpoints don't use trusted certs)
  
   ```
   defaults_json_path=~/ansible/local/lib/python2.7/site-packages/os_client_config/defaults.json; grep -q verify $defaults_json_path || sed -i '/{$/a "verify": false,' $defaults_json_path
   ```

5. Install the SSH private key

   The build node / workstation will need to login via SSH to the cluster nodes.
   
   For this to succeed, the SSH private key needs to be placed on the build node / workstation, normally under .ssh, for example: `~/.ssh/field.pem`. It can be placed under any path as this file will be referenced later.
   
   It should have `400` permissions: `chmod 0400 ~/.ssh/field.pem`.
   
   The SSH public key must be present on the OpenStack environment as it will be referenced when the nodes will be built (this can be checked on the Dashboard, under `Compute` -> `Access and Security` -> `Key Pairs` tab).


# Setup the OpenStack credentials

1. Download the OpenStack RC file

   Login to your OpenStack dashboard, and download your user specific OpenStack RC file.
   This is usually found on `Compute` -> `Access and Security` under the `API Access` tab. Download the v3 if available.


2. Apply the OpenStack credentials

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

Upload the ansible-hdp repository to the build node / workstation, preferable under the home folder.

If the build node / workstation can directly download the repository, run the following:

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
| name_suffix     | A suffix that will be appended to the name of all nodes. Usually it's a domain, but can be anything or even the empty string `''`. |
| zone            | The name of the OpenStack zone.                         |
| admin_username  | The Linux user with sudo permissions. This user is specific to the image used. For example, in a CentOS image, it can be `centos` or in a Ubuntu image it can be `ubuntu`. |
| ssh.keyname     | The name of the SSH key that will be placed on cluster nodes at build time. This SSH key must already exist in the OpenStack environment. |
| ssh.privatekey  | Local path to the SSH private key that will be used to login into the nodes. This is the key uploaded to the build node as part of the Build Setup, step 5. |


## nodes config

This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

There can be any number of groups so other groups can be added to correspond with the required architecture.

And groups can have any name and any number of nodes but group names should correspond with the host groups in the Ambari Blueprint.

| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the OpenStack Zone. Usually it contains the cluster name. It's used to derive the nodes names (if node count is greater than 1, numbers will be appended to the group name to uniquely identify nodes). |
| count           | The number of nodes to be built in this group. |
| image           | The name or ID of the OS image to be used. A list of the available images can be found by running `nova --insecure image-list`. |
| flavor          | The name or ID of the flavor / size of the node. A list of all the available flavors can be found by running `nova --insecure flavor-list`. |                                                      |
| public_ip       | If the Public IP of the cluster node should be used when connecting to it. Required if the build node does not have access to the private IP range of the cluster nodes. |
| ambari_server   | Set it to `true` if the group also runs an Ambari Server. The number of nodes in this group should be 1. If there are more than 1 node, ambari-server will be installed on all of them, but only the first one (in alphabetical order) will be used by the Ambari Agents. |


# Build the Cloud environment

Run the script that will build the Cloud environment.

Set first the `CLOUD_TO_USE` environment variable to `openstack`.

```
export CLOUD_TO_USE=openstack
cd ~/ansible-hdp*/ && bash build_cloud.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
source ~/*-openrc.sh
```


# Set the cluster variables

## all config

Modify the file at `~/ansible-hdp/playbooks/group_vars/all` to set the cluster configuration.

| Variable          | Description                                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------------------------------- |
| cluster_name      | The name of the cluster.                                                                                |
| ambari_version    | The Ambari version, in the full, 4-number form, for example: `2.4.2.0`.                                     |
| product.name      | The product name, `hdp` for HDP and `hdf` for HDF.                                                          |
| product.version   | The product version, in the full, 4-number form, for example: `2.5.3.0`.                                    |
| utils_version     | The HDP-UTILS version exactly as displayed on the [repositories page](http://docs.hortonworks.com/HDPDocuments/Ambari-2.4.2.0/bk_ambari-installation/content/hdp_stack_repositories.html). This should be set to `1.1.0.21` for HDP 2.5 or HDF, and to `1.1.0.20` for any HDP less than 2.5.|
| base_url          | The base URL for the repositories. Change this to the local web server url if using a Local Repository. `/HDP/<OS>/2.x/updates/<latest.version>` (or `/HDF/..`) will be appended to this value to set it accordingly if there are additional URL paths. |
| mpack_filename    | The exact filename of the mpack to be installed as displayed on the [repositories page](http://docs.hortonworks.com/HDPDocuments/HDF2/HDF-2.1.2/bk_dataflow-release-notes/content/ch_hdf_relnotes.html#repo-location). Example for HDF 2.1.2: `hdf-ambari-mpack-2.1.2.0-10.tar.gz`. |


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


# Install the cluster

Run the script that will install the cluster using Blueprints while taking care of the necessary prerequisites.

Make sure you set the `CLOUD_TO_USE` environment variable to `openstack`.

```
export CLOUD_TO_USE=openstack
cd ~/ansible-hdp*/ && bash install_cluster.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
source ~/*-openrc.sh
```


This script will apply all the required playbooks in one run, but you can also apply the individual playbooks by running the following wrapper scripts:

- Prepare the nodes: `prepare_nodes.sh`
- Install Ambari: `install_ambari.sh`
- Configure Ambari: `configure_ambari.sh`
- Apply Blueprint: `apply_blueprint.sh`
