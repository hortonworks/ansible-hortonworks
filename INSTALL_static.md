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

The static inventory puts the nodes in different groups as described in the [Ansible Documentation](http://docs.ansible.com/ansible/intro_inventory.html#hosts-and-groups).

Each group defines a specific node role, for example master, slave, edge.

The following variables can be set for each node:

| Variable                      | Description                                                                                                 |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------- |
| ansible_host                  | The DNS name or IP of the host to connect to.                                                               |
| ansible_user                  | The Linux user with sudo permissions that Ansible will use to connect to the host (doesn't have to be root. |                         |
| ansible_ssh_pass              | (Optional) The SSH password to use when connecting to the host (this is the password of the `ansible_user`). Either this or `ansible_ssh_private_key_file` should be configured. |
| ansible_ssh_private_key_file  | (Optional) Local path to the SSH private key that will be used to login into the host. Either this or `ansible_ssh_pass` should be configured. |
| ambari_server                 | Set it to `true` for the host that should also run the Ambari Server.                                       |

# Test the inventory

List the inventory:

```
ansible -i inventory/static all --list-hosts
```

Confirm access to hosts in the inventory:

```
ansible -i inventory/static all -m setup
```

# Set the cluster variables

## cluster config file

Modify the file at `~/ansible-hdp/playbooks/group_vars/all` to set the cluster configuration.

| Variable                   | Description                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| cluster_name               | The name of the cluster.                                                                                    |
| ambari_version             | The Ambari version, in the full, 4-number form, for example: `2.5.1.0`.                                     |
| hdp_version                | The HDP version, in the full, 4-number form, for example: `2.6.1.0`.                                        |
| hdf_version                | The HDF version, in the full, 4-number form, for example: `3.0.1.0`.                                        |
| utils_version              | The HDP-UTILS version exactly as displayed on the [repositories page](https://docs.hortonworks.com/HDPDocuments/Ambari-2.5.1.0/bk_ambari-installation/content/hdp_stack_repositories.html). This should be set to `1.1.0.21` for HDP 2.5 or HDF, and to `1.1.0.20` for any HDP less than 2.5.|
| base_url                   | The base URL for the repositories. Change this to the local web server url if using a Local Repository. `/HDP/<OS>/2.x/updates/<latest.version>` (or `/HDF/..`) will be appended to this value to set it accordingly if there are additional URL paths. |
| mpack_filename             | The exact filename of the mpack to be installed as displayed on the [repositories page](https://docs.hortonworks.com/HDPDocuments/HDF3/HDF-3.0.1/bk_release-notes/content/ch_hdf_relnotes.html#repo-location). Example for HDF 3.0.1: `hdf-ambari-mpack-3.0.1.0-43.tar.gz`. |
| java                       | Can be set to `embedded` (default - downloaded by Ambari), `openjdk` or `oraclejdk`. If `oraclejdk` is selected, then the `.x64.tar.gz` package must be downloaded in advance from [Oracle](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html). Same with the [JCE](http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html) package. These files can be copied to all nodes in advanced or only to the Ansible Controller and Ansible will copy them. This behaviour is controlled by the `oraclejdk_options.remote_files` setting. |
| oraclejdk_options          | These options are only relevant if `java` is set to `oraclejdk`. |
| .base_folder               | This indicates the folder where the Java package should be unpacked to. The default of `/usr/java` is also used by the Oracle JDK rpm. |
| .tarball_location          | The location of the tarball file. This can be the location on the remote systems or on the Ansible controller, depending on the `remote_files` variable. |
| .jce_location              | The location of the JCE package zip file. This can be the location on the remote systems or on the Ansible controller, depending on the `remote_files` variable. |
| .remote_files              | If this variable is set to `yes` then the tarball and JCE files must already be present on the remote system. If set to `no` then the files will be copied by Ansible (from the Ansible controller to the remote systems). |
| external_dns               | This controls the type of DNS to be used. If `yes` it will use whatever DNS is currently set up. If `no` it will populate the `/etc/hosts` file with all cluster nodes. |
| disable_firewall           | This variable controls the local firewall service (iptables, firewalld, ufw). Sometimes, a local firewall service might run and block inter-node cluster communication. In these circumstances the local firewall service should be disabled as traffic rules should be provided by an external firewall such as a Cisco ASA. Set to `yes` to disable the existing local firewall service if it blocks the inter-node cluster communication. |

### security configuration

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| security                       | This variable controls the Kerberos security configuration. If set to `none`, Kerberos will not be enabled. Otherwise the choice is between `mit-kdc` or `active-directory`. |
| security_options               | These options are only relevant if `security` is not `none`. All of the options here are used for an Ambari managed security configuration. No manual option is available at the moment. |
| .external_hostname             | The hostname/IP of the Kerberos server. This can be an existing Active Directory or [MIT KDC](https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.1/bk_security/content/_optional_install_a_new_mit_kdc.html). If left empty `''` then the playbooks will install the MIT KDC on the Ambari node and prepare everything. |
| .realm                         | The realm that will be used when creating service principals. |
| .admin_principal               | The Kerberos principal that has the permissions to create new users. No need to append the realm to this value. In case of Active Directory, this user must have `Create, delete, and manage user accounts` permissions over the OU container. If installing a new MIT KDC this user will be created by the playbook. |
| .admin_password                | The password for the above user. |
| .kdc_master_key                | The master password for the Kerberos database. Only used when installing a new MIT KDC (when `security` is `mit-kdc` and `external_hostname` is set to `''`. |
| .ldap_url                      | The URL to the Active Directory LDAPS interface. Only used when `security` is set to `active-directory`. |
| .container_dn                  | The distinguished name (DN) of the container that will store the service principals. Only used when `security` is set to `active-directory`. |
| .http_authentication           | Set to `yes` to enable Kerberos HTTP authentication (SPNEGO) for most UIs.


## ambari-server config file

Modify the file at `~/ansible-hdp/playbooks/group_vars/ambari-server` to set the Ambari Server specific configuration.

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ambari_admin_user              | The Ambari admin username, normally `admin`.                                                               |
| ambari_admin_password          | The Ambari password of the `ambari_admin_user` user previously set.                                        |
| wait / wait_timeout            | Set this to `true` if you want the playbook to wait for the cluster to be successfully built after applying the blueprint. The timeout setting controls for how long (in seconds) should it wait for the cluster build. |
| default_password               | A default password for all required passwords which are not specified in the blueprint.                                                                               |
| config_recommendation_strategy | Configuration field which specifies the strategy of applying configuration recommendations to a cluster as explained in the [documentation](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure). |
| cluster_template_file          | The path to the cluster creation template file that will be used to build the cluster. It can be an absolute path or relative to the `ambari-blueprint/templates` folder. The default should be sufficient as it uses [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) to generate the file. |

### database configuration

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| database                       | The type of database that should be used. A choice between `embedded` (Ambari default), `postgres`, `mysql` or `mariadb`. |
| database_options               | These options are only relevant for the non-`embedded` database. |
| .external_hostname             | The hostname/IP of the database server. This needs to be prepared as per the [documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.5.1.0/bk_ambari-administration/content/ch_amb_ref_using_non_default_databases.html). No need to load any schema, this will be done by Ansible, but the users and databases must be created in advance. If left empty `''` then the playbooks will install the database server on the Ambari node and prepare everything. To change any settings (like the version or repository path) modify the OS specific files under the `playbooks/roles/database/vars/` folder. |
| .ambari_db_name                | The name of the database Ambari should use. |
| .ambari_db_username            | The username that Ambari should use to connect to its database. |
| .ambari_db_password            | The password for the above user. |
| .hive_db_name                  | The name of the database Hive should use. |
| .hive_db_username              | The username that Hive should use to connect to its database. |
| .hive_db_password              | The password for the above user. |
| .oozie_db_name                 | The name of the database Oozie should use. |
| .oozie_db_username             | The username that Oozie should use to connect to its database. |
| .oozie_db_password             | The password for the above user. |
| .rangeradmin_db_name           | The name of the database Ranger Admin should use. |
| .rangeradmin_db_username       | The username that Ranger Admin should use to connect to its database. | |
| .rangeradmin_db_password       | The password for the above user. |

### ranger configuration

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ranger_options                 | These options are only relevant if `RANGER_ADMIN` is a component of the dynamic Blueprint stack.           |
| .ranger_admin_password         | The password for the Ranger admin users (both admin and amb_ranger_admin).                                 |
| .enable_plugins                | If set to `yes` the plugins for all of the available services will be enabled. With `no` Ranger would be installed but not functional. |

### blueprint configuration

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| blueprint_name                 | The name of the blueprint as it will be stored in Ambari.                                                  |
| blueprint_file                 | The path to the blueprint file that will be uploaded to Ambari. It can be an absolute path or relative to the `roles/ambari-blueprint/templates` folder. The blueprint file can also contain [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) variables. |
| blueprint_dynamic              | Settings for the dynamic blueprint template - only used if `blueprint_file` is set to `blueprint_dynamic.j2`. The role names must match the groups from the inventory setting file `~/ansible-hdp/inventory/static/group_vars/all`. The chosen components are split into two lists: clients and services. The chosen Component layout must respect Ambari Blueprint restrictions - for example if a single `NAMENODE` is configured, there must also be a `SECONDARY_NAMENODE` component. |


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
- Post Install: `post_install.sh`
