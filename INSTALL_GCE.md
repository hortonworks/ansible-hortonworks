ansible-hdp installation guide
------------------------------

* These Ansible playbooks will build a Cloud environment on Google Compute Engine.
* And then deploy a Hortonworks cluster (either Hortonworks Data Platform or Hortonworks DataFlow) using Ambari Blueprints.

---


# Build setup

Before building anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH and to the Google Compute Engine APIs via HTTPS.


## CentOS/RHEL 7

1. Install the required packages

   ```
   sudo yum -y install epel-release || sudo yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   sudo yum -y install gcc gcc-c++ python-virtualenv python-pip python-devel libffi-devel openssl-devel sshpass git vim-enhanced
   ```


2. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate 
   ```


3. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade   
   pip install pycparser ansible backports.ssl_match_hostname apache-libcloud
   ```


4. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists). Replace `google-user` with the non-root administrative user you want to use to login to the cluster nodes. You can also specify a different path for the key. 

   ```
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -C google-user
   ```


## Ubuntu 14+

1. Install required packages:

   ```
   sudo apt-get update
   sudo apt-get -y install unzip python-virtualenv python-pip python-dev sshpass git libffi-dev libssl-dev vim
   ```


2. Create and source the Python virtual environment

   ```
   virtualenv ~/ansible; source ~/ansible/bin/activate  
   ```


3. Install the required Python packages inside the virtualenv

   ```
   pip install setuptools --upgrade
   pip install pip --upgrade
   pip install pycparser ansible backports.ssl_match_hostname apache-libcloud
   ```


4. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists). Replace `google-user` with the non-root administrative user you want to use to login to the cluster nodes. You can also specify a different path for the key. 

   ```
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -C google-user
   ```


# Setup the Google account and credentials

To use the Ansible gce modules, you'll need to obtain the API credentials in the JSON format.

More details about how authentication to the Google Cloud Platform works is on the [Ansible Guide](http://docs.ansible.com/ansible/guide_gce.html).

1. Create a Google Cloud Platform Service Account

   1. Go to the [Service accounts page](https://console.developers.google.com/permissions/serviceaccounts) and login with your Google account.
    
   2. Decide on a project you want to use for the purpose of these scripts or create a new project in the `All projects` page.
   
   3. Once the project has been selected, click on the `CREATE SERVICE ACCOUNT` link.
   
   4. Give the Service account a name and a Role (recommended Role is `Project` -> `Editor`).
   
   5. Also select the `Furnish a new private key` option and `JSON` as the Key type. This will also initiate a download of the JSON file holding the service account's credentials. Save this file.
   
   6. If this is a new project, you'll also need to [associate a Billing Account](https://console.cloud.google.com/billing/projects) with the project (and create a [new Billing Account](https://console.cloud.google.com/billing) if none exists). If this was done, confirm that everything works by going to the [main Compute Engine page](https://console.cloud.google.com/compute/instances).


2. Download JSON credentials

   If you haven't downloaded the JSON credentials file from the above step, or you already have a Service Account, go to the [Credentials page](https://console.cloud.google.com/apis/credentials) and select `Create credentials` > `Service account key`.
   
   Select your Service Account and `Create` the `JSON` key.


3. Upload the JSON credentials

   Once the JSON credentials file is obtained, uploaded it to the build node / workstation in any folder you prefer.
   
   This location will be referenced by an environment variable.


4. Export the environment variables

   There are different ways to provide the credentials to the Ansible modules, each with its own advantages and disadvantages:
   * set variables directly inside the Ansible playbooks
   * populate a `secrets.py` file
   * setting environment variables

   All of these are explained in greater details on the [Ansible Guide](http://docs.ansible.com/ansible/guide_gce.html) but for the purpose of this guide we'll use the following environment variables:
  
   * **GCE_EMAIL**: the email account associated with the project (can be found on the [Service accounts](https://console.cloud.google.com/iam-admin/serviceaccounts) page -> `Service account ID` column)
   * **GCE_PROJECT**: the id of the project (can be found on the [All projects](https://console.cloud.google.com/iam-admin/projects) page)
   * **GCE_CREDENTIALS_FILE_PATH**: the local path to the JSON credentials file

   ```
   export GCE_EMAIL=hadoop-test@hadoop-123456.iam.gserviceaccount.com
   export GCE_PROJECT=hadoop-123456
   export GCE_CREDENTIALS_FILE_PATH=~/Hadoop-12345cb6789d.json
   export GCE_PEM_FILE_PATH=$GCE_CREDENTIALS_FILE_PATH
   ```


# Upload the SSH public key to Google

Do the following to upload the SSH public key to the Google project.

This is based on Google's [guide](https://cloud.google.com/compute/docs/instances/connecting-to-instance#generatesshkeypair).

1. Obtain the SSH public key

   Obtain the contents of the public key file (you can use the `cat` command).
    
   This can be an existing key or the one generated as part of the Build Setup, step 4:
    
   ```
   cat ~/.ssh/id_rsa.pub
   ```


2. Add the key contents to Google Compute Engine

   Go to the [METADATA PAGE](https://console.cloud.google.com/compute/metadata) and click on the `SSH Keys` tab.
   
   Click `Edit` and add the new key. When you paste the contents of the public key file obtained at the previous step, Google Compute Engine will automatically generate the Username, which is the non-root administrative user that is used to login to the cluster nodes.
   
   If you've used a different key than the one generated as part of the Build Setup, step 4, or you want to use a different user to login to the cluster nodes, replace the last bit of the key with the desired username.
   
   In this guide, the username used is `google-user`.


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


# Set the GCE variables

Modify the file at `~/ansible-hdp/inventory/gce/group_vars/all` to set the GCE configuration.


## cloud_config
This section contains variables that are cluster specific and are used by all nodes:

| Variable           | Description                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| name_suffix        | A suffix that will be appended to the name of all nodes. Must be lowercase letters, numbers and hyphens or even the empty string `''`. |
| zone               | The Google Cloud Platform Zone as described [here](https://cloud.google.com/compute/docs/regions-zones/regions-zones). |
| admin_username     | The Linux user with sudo permissions. This is the Username generated by GCE from the previously uploaded SSH public key. |
| ssh.privatekey     | Local path to the SSH private key that will be used to login into the nodes. This can be the key generated as part of the Build Setup, step 4. |
| network            | The Google Cloud Platform network as described [here](https://cloud.google.com/compute/docs/networking). It will be created if it doesn't exist. |


## firewall_rules
This is a separate section, just for firewall rules inside the network segment.

By default, the `allow-internal` type of rule should always be present, otherwise nodes would not be able to talk to each other.

| Variable         | Description                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------- |
| name             | The name of the rule. The examples contain the `network.name` to be more easily identifiable. |
| allowed          | The protocol:ports to allow. The syntax allows multiple ports and protocols to be defined as long as they are split by `;`. For example: `tcp:80` or `tcp:80,443` or `tcp:80-800;udp:1-25`.|
| src_range        | The IP source range, in CIDR notation. Any network / all sources can be identified with `0.0.0.0/0`. |
| target_groups    | The target node group that this rule should be applied to. To apply to all targets / the whole subnet, leave an empty list as shown. |


## nodes config
This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

There can be any number of groups.

And groups can have any names and any number of nodes but they should correspond with the host groups in the Ambari Blueprint.

| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the same Google project. Usually it contains the cluster name. Other groups can be added to correspond with the required architecture. |
| count           | The number of nodes to be built in this group. |
| image           | The OS image to be used. More details [here](https://cloud.google.com/compute/docs/images). |
| type            | The machine type / size of the node. A list of all the machine-types can be found [here](https://cloud.google.com/compute/docs/machine-types) and the pricing [here](https://cloud.google.com/compute/pricing#machinetype). |
| public_ip       | If the VM should have a Public IP assigned to it. Required if the build node does not have access to the private IP range of the cluster nodes. |
| root_disk       | By default, each Compute Engine instance has a single root [Persistent disk](https://cloud.google.com/compute/docs/disks/) that contains the operating system. The default size of the root volume / disk is 10GB, so use this variable to set the size of the root disk to the desired value. More details [here](https://cloud.google.com/compute/docs/disks/performance) about disk types and performance. |
| ambari_server   | Set it to `true` if the group also runs an Ambari Server. The number of nodes in this group should be 1. If there are more than 1 node, ambari-server will be installed on all of them, but only the first one (in alphabetical order) will be used by the Ambari Agents. |


# Build the Cloud environment

Run the script that will build the Cloud environment.

Set first the `CLOUD_TO_USE` environment variable to `gce`.

```
export CLOUD_TO_USE=gce
cd ~/ansible-hdp*/ && bash build_cloud.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
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
| disable_firewall           | This variable controls the local firewall service (iptables, firewalld, ufw). Sometimes, a local firewall service might run and block inter-node cluster communication. In these circumstances the local firewall service should be disabled as traffic rules should be provided by an external firewall such as Security Groups. Set to `yes` to disable the existing local firewall service if it blocks the inter-node cluster communication. |


## ambari-server config file

Modify the file at `~/ansible-hdp/playbooks/group_vars/ambari-server` to set the Ambari Server specific configuration.

| Variable                       | Description                                                                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| ambari_admin_user              | The Ambari admin username, normally `admin`.                                                               |
| ambari_admin_password          | The Ambari password of the `ambari_admin_user` user previously set.                                        |
| wait / wait_timeout            | Set this to `true` if you want the playbook to wait for the cluster to be successfully built after applying the blueprint. The timeout setting controls for how long (in seconds) should it wait for the cluster build. |
| default_password               | A default password for all required passwords which are not specified in the blueprint.                                                                               |
| config_recommendation_strategy | Configuration field which specifies the strategy of applying configuration recommendations to a cluster as explained in the [documentation](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure). |
| cluster_template_file          | The path to the cluster creation template file that will be used to build the cluster. It can be an absolute path or relative to the `ambari-blueprint/templates`  folder. The default should be sufficient for cloud builds as it uses the `cloud_config` variables and [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) to generate the file. |

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
| blueprint_file                 | The path to the blueprint file that will be uploaded to Ambari. It can be an absolute path or relative to the `roles/ambari-blueprint/templates`  folder. The blueprint file can also contain [Jinja2 Template](http://jinja.pocoo.org/docs/dev/templates/) variables. |
| blueprint_dynamic              | Settings for the dynamic blueprint template - only used if `blueprint_file` is set to `blueprint_dynamic.j2`. The group names must match the groups from the inventory setting file `~/ansible-hdp/inventory/gce/group_vars/all`. The chosen components are split into two lists: clients and services. The chosen Component layout must respect Ambari Blueprint restrictions - for example if a single `NAMENODE` is configured, there must also be a `SECONDARY_NAMENODE` component. |


# Install the cluster

Run the script that will install the cluster using Blueprints while taking care of the necessary prerequisites.

Make sure you set the `CLOUD_TO_USE` environment variable to `gce`.

```
export CLOUD_TO_USE=gce
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
