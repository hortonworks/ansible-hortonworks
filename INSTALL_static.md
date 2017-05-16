ansible-hdp installation guide
------------------------------

* These Ansible playbooks will deploy a Hortonworks cluster (either Hortonworks Data Platform or Hortonworks DataFlow) using Ambari Blueprints and a static inventory.

* What is a static inventory is described in the [Ansible Documentation](http://docs.ansible.com/ansible/intro_inventory.html).

* Using the static inventory implies that the nodes are already built and accessible via SSH.


---


# Workstation setup

Before deploying anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH.

It can even be one of the cluster nodes.


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
   pip install pycparser functools32 pytz ansible
   ```


4. (Optional) Generate the SSH private key

   The build node / workstation will need to login via SSH to the cluster nodes.
   
   This can be done either by using a username and a password or with SSH keys.
   
   For the SSH keys method, the SSH private key needs to be placed or generated on the workstation, normally under .ssh, for example: `~/.ssh/id_rsa`.
   
   To generate a new key, run the following:

   ```
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -C google-user
   ```


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
   pip install pycparser functools32 pytz ansible
   ```


4. (Optional) Generate the SSH private key

   The build node / workstation will need to login via SSH to the cluster nodes.
   
   This can be done either by using a username and a password or with SSH keys.
   
   For the SSH keys method, the SSH private key needs to be placed or generated on the build node / workstation, normally under .ssh, for example: `~/.ssh/id_rsa`.
   
   To generate a new key, run the following:

   ```
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -C google-user
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


# Set the static inventory

Modify the file at `~/ansible-hdp/inventory/static` to set the static inventory.

The static inventory puts the hosts in different groups as described in the [Ansible Documentation](http://docs.ansible.com/ansible/intro_inventory.html#hosts-and-groups).

The following variables can be set for each host:

| Variable                      | Description                                                                                                 |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| ansible_host                  | The DNS name or IP of the host to connect to.                                                               |
| ansible_user                  | The Linux user with sudo permissions that Ansible will use to connect to the host (doesn't have to be root. |                         |
| ansible_ssh_pass              | (Optional) The SSH password to use when connecting to the host (this is the password of the `ansible_user`). Either this or `ansible_ssh_private_key_file` should be configured. |
| ansible_ssh_private_key_file  | (Optional) Local path to the SSH private key that will be used to login into the host. Either this or `ansible_ssh_pass` should be configured. |
| ambari_server                 | Set it to `true` for the host that should also run the Ambari Server.                                       |


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
| default_password               | A default password for all required passwords which are not specified in the blueprint.                                                                               |
| config_recommendation_strategy | Configuration field which specifies the strategy of applying configuration recommendations to a cluster as explained in the [documentation](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure). |
| cluster_template_file          | The path to the cluster creation template file that will be used to build the cluster. It can be an absolute path or relative to the `ambari-blueprint/templates`  folder. The default should be sufficient for cloud builds as it uses the `cloud_config` variables and [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) to generate the file. |
| blueprint_name                 | The name of the blueprint as it will be stored in Ambari.                                                  |
| blueprint_file                 | The path to the blueprint file that will be uploaded to Ambari. It can be an absolute path or relative to the `roles/ambari-blueprint/templates`  folder. The blueprint file can also contain [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) variables. |
| blueprint_dynamic              | Settings for the dynamic blueprint template - only used if `blueprint_file` is set to `blueprint_dynamic.j2`. The group names must match the groups from the inventory setting file `~/ansible-hdp/inventory/static/group_vars/all`. The chosen components are split into two lists: clients and services. The chosen Component layout must respect Ambari Blueprint restrictions - for example if a single `NAMENODE` is configured, there must also be a `SECONDARY_NAMENODE` component. |


# Install the cluster

Run the script that will install the cluster using Blueprints while taking care of the necessary prerequisites.

Make sure you set the `CLOUD_TO_USE` environment variable to `static`.

```
export CLOUD_TO_USE=static
cd ~/ansible-hdp*/ && bash install_cluster.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
```


This script will apply all the required playbooks in one run, but you can also apply the individual playbooks by running the following wrapper scripts:

- Prepare the nodes: `prepare_nodes.sh`
- Install Ambari: `install_ambari.sh`
- Configure Ambari: `configure_ambari.sh`
- Apply Blueprint: `apply_blueprint.sh`
