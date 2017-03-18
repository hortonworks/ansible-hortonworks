ansible-hdp installation guide
------------------------------

* These Ansible playbooks can build a Cloud environment on AWS.

---


# Build setup

Before building anything, the build node / workstation from where Ansible will run should be prepared.

This node must be able to connect to the cluster nodes via SSH and to the AWS APIs via HTTPS.


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
   pip install pycparser ansible boto
   ```


4. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists):

   ```
   ssh-keygen -q -t rsa
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
   pip install pycparser ansible boto
   ```


4. Generate the SSH public/private key pair that will be loaded onto the cluster nodes (if none exists):

   ```
   ssh-keygen -q -t rsa
   ```


# Setup the AWS credentials file

Ansible AWS modules use the boto Python library. Boto can manage credentials using a config file (more details [here](http://boto.readthedocs.io/en/latest/boto_config_tut.html) but for the purpose of this guide we'll use environment variables.


1. Get the AWS access key and secret

   Decide on the account you want to use for the purpose of these scripts or create a new one in IAM (with a `PowerUserAccess` policy attached to it).
   
   [Create](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) an Access Key if none is present.
   
   Obtain the `Access Key ID` and the `Secret Access Key`.


2. Export the environment variables

   With the Access Key details obtained, export them as environment variables:
 
   ```
   export AWS_ACCESS_KEY_ID='AK123'
   export AWS_SECRET_ACCESS_KEY='abc123'
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


# Set the AWS variables

Modify the file at `~/ansible-hdp/inventory/aws/group_vars/all` to set the AWS configuration.

## name_prefix
A helper variable that can be used to precede the name of the nodes nodes and other AWS resources (such as the subnet or NICs).

Node names are derived from the group name (more details about groups bellow) and this variable can be used to uniquely identify a certain cluster, especially if the Resource Group is shared.


## cloud_config
This section contains variables that are cluster specific and are used by all nodes:

| Variable           | Description                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------------- |
| name_suffix        | A suffix that will be appended to the name of all nodes. Usually it's a domain, but can be anything or even the empty string `''`. |
| region             | The AWS Region as described [here](http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region). |
| zone               | The AWS Availability Zone from the previously set Region. More details [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#using-regions-availability-zones-describe). |
| vpc_name /vpc_cidr | The Amazon Virtual Private Cloud as described [here](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html). It will be created if it doesn't exist. The name and the CIDR uniquely identify a VPC so set these variables accordingly if you want to build in an existing VPC. |
| subnet_cidr        | Subnet is a range of IP addresses in the VPC as described [here](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html). |
| internet_gateway   | Set this to `true` if the VPC has an Internet Gateway. Without one, the cluster nodes cannot reach the Internet (useful to download packages) so only set this to `false` if the nodes will use repositories located in the same VPC. More details about Internet Gateways [here](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Internet_Gateway.html). |
| admin_username     | The Linux user with sudo permissions. Usually this is `ec2-user`.                                          |
| ssh.keyname        | The name of the AWS SSH key that will be placed on cluster nodes at build time. Can be an existing one otherwise a new key will be uploaded. |
| ssh.privatekey     | Local path to the SSH private key that will be used to login into the nodes. This can be the key generated as part of the Build Setup, step 5. |
| ssh.publickey      | Local path to the SSH public key that will be placed on cluster nodes at build time. This public key will be uploaded to AWS if one doesn't exist. |
| security_groups    | A list of Access Control List (ACL) associated with the subnet. Details [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#vpc-security-groups). By default, nodes in the same security group are not allowed to communicate to each other unless there is a rule to allow traffic originating from the same group. This rule is defined in the `default_cluster_access` security group and should be kept as it is. |


## nodes config

This section contains variables that are node specific.

Nodes are separated by groups, for example master, slave, edge.

There can be any number of groups.

And groups can have any names and any number of nodes but they should correspond with the host groups in the Ambari Blueprint.

| Variable        | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| group           | The name of the group. Must be unique in the AWS VPC. This is the reason why the default contains the `name_prefix`. Other groups can be added to correspond with the required architecture. |
| count           | The number of nodes to be built in this group. |
| image           | The AMI ID of the OS image to be used. More details [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html). The easiest way to find out the ID is by using the EC2 console and clicking on the `Launch Instance` button. |
| type            | The instance-type / size of the node. A list of all the instance-types can be found [here](https://aws.amazon.com/ec2/instance-types/) and the pricing [here](https://aws.amazon.com/ec2/pricing/). |
| public_ip       | If the VM should have a Public IP assigned to it. Required if the build node does not have access to the private IP range of the cluster nodes. |
| security_groups | The security groups that should be applied to the node. The nodes should have at least the default security group that allows traffic in the same group. |
| root_volume     | The vast majority of AMIs require an EBS root volume. The default size of this root volume is small, irrespective of the instance-type, so use this variable to set the size of the root volume to the desired value. More details about root devices [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/RootDeviceStorage.html) and about types of EBS Volumes [here](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html). |
| ambari_server   | Set it to `true` if the group also runs an Ambari Server. The number of nodes in this group should be 1. If there are more than 1 node, ambari-server will be installed on all of them, but only the first one (in alphabetical order) will be used by the Ambari Agents. |


# Build the Cloud environment

Run the script that will build the Cloud environment.

Set first the `CLOUD_TO_USE` environment variable to `aws`.

```
export CLOUD_TO_USE=aws
cd ~/ansible-hdp*/ && bash build_cloud.sh
```

You may need to load the environment variables if this is a new session:

```
source ~/ansible/bin/activate
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

Make sure you set the `CLOUD_TO_USE` environment variable to `aws`.

```
export CLOUD_TO_USE=aws
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
