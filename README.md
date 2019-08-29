ansible-hortonworks
-----------

These Ansible playbooks will build a Hortonworks cluster (Hortonworks Data Platform and / or Hortonworks DataFlow) using Ambari Blueprints. For a full list of supported features check [below](#features).

- Tested with: HDP 3.0 -> 3.1, HDP 2.4 -> 2.6.5, HDP Search 3.0 -> 4.0, HDF 2.0 -> 3.4, Ambari 2.4 -> 2.7 (the versions must be matched as per the [support matrix](https://supportmatrix.hortonworks.com)).

- This includes building the Cloud infrastructure (optional) and taking care of the prerequisites.

- The aim is to first build the nodes in a Cloud environment, prepare them (OS settings, database, KDC, etc) and then install Ambari and create the cluster using Ambari Blueprints.
  - If the infrastructure is already built (Terraform, bare-metal, etc.), it can also use a [static inventory](inventory/static).
  - For a detailed Terraform implementation check the following: [https://dataengi.com/2018/09/21/terraform-hdp](https://dataengi.com/2018/09/21/terraform-hdp).

- It can use a static blueprint or a [dynamically generated](playbooks/roles/ambari-blueprint/templates/blueprint_dynamic.j2) one based on the components from the Ansible [variables file](playbooks/group_vars/all#L161).
  - The dynamic blueprint gives the freedom to distribute components for a chosen topology but this topology must respect Ambari Blueprint restrictions (e.g. if a single `NAMENODE` is set, there must also be a `SECONDARY_NAMENODE`).
  - Another advantage of the dynamic blueprint is that it generates the correct blueprint for when using [HA services](playbooks/roles/ambari-blueprint/templates/blueprint_dynamic.j2#L440), or [external databases](playbooks/roles/ambari-blueprint/templates/blueprint_dynamic.j2#L504) or [Kerberos](playbooks/roles/ambari-blueprint/templates/blueprint_dynamic.j2#L3).


## DISCLAIMER

These Ansible playbooks offer a specialised way of deploying Ambari-managed Hortonworks clusters.
To use these playbooks you'll need to have a good understanding of both [Ansible](https://docs.ansible.com/ansible/latest/index.html) and [Ambari Blueprints]( https://cwiki.apache.org/confluence/display/AMBARI/Blueprints).

This is not a Hortonworks product and these playbooks are not officially supported by Hortonworks.

For a fully Hortonworks-supported and user friendly way of deploying Ambari-managed Hortonworks clusters, please check [Cloudbreak](https://docs.hortonworks.com/HDPDocuments/Cloudbreak/Cloudbreak-2.7.2/content/index.html) first.


## [Installation Instructions](id:instructions)

- AWS: See [INSTALL.md](INSTALL_AWS.md) for AWS build instructions and cluster installation.
- Azure: See [INSTALL.md](INSTALL_Azure.md) for Azure build instructions and cluster installation.
- Google Compute Engine: See [INSTALL.md](INSTALL_GCE.md) for GCE build instructions and cluster installation.
- OpenStack: See [INSTALL.md](INSTALL_OpenStack.md) for OpenStack build instructions and cluster installation.
- Static inventory: See [INSTALL.md](INSTALL_static.md) for cluster installation on pre-built environments.


## [Requirements](id:requirements)

- Ansible 2.5+

- Expects CentOS/RHEL, Ubuntu, Amazon Linux or SLES hosts


## [Concepts](id:concepts)

The core concept of these playbooks is the `host_groups` field in the [Ambari Blueprint](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-BlueprintFieldDescriptions).
This is an essential piece of Ambari Blueprints that maps the topology components to the actual servers.

The `host_groups` field in the [Ambari Blueprint](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-BlueprintFieldDescriptions) logically groups the components, while the `host_groups` field in the [Cluster Creation Template](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure) maps these logical groups to the actual servers that will run the components.

Therefore, these Ansible playbooks try to take advantage of Blueprint's `host_groups` and map the Ansible inventory groups to the `host_groups` using a Jinja2 template: [cluster_template.j2](playbooks/roles/ambari-blueprint/templates/cluster_template.j2#L32).

<p align="center">
  <img src="https://user-images.githubusercontent.com/5119993/43648111-699606a6-9731-11e8-8dcb-71c0c47f482a.png">
</p>

- If the blueprint is dynamic, these `host_groups` are defined in the [variable file](playbooks/group_vars/all#L162) and they need to match the Ansible inventory groups that will run those components.
- If the blueprint is static, these `host_groups` are defined in the [blueprint itself](playbooks/roles/ambari-blueprint/files/blueprint_hdfs_only.json#L27) and they need to match the Ansible inventory groups that will run those components.


### Cloud inventory
A special mention should be given when using a Cloud environment and / or a [dynamic Ansible inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html).

In this case, building the Cloud environment is decoupled from building the Ambari cluster, and there needs to be a way to tie things together - the Cloud nodes to the Blueprint layout (e.g. on which Cloud node the `NAMENODE` should run).

This is done using a feature that exists in all (or most) Clouds: [Tags](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html). The Ansible dynamic inventory takes advantage of this Tag information and creates an Ansible inventory group for each Tag.

If these playbooks are also used to build the Cloud environment, the nodes need to be grouped together in the [Cloud inventory variables file](inventory/aws/group_vars/all#L27). This information is then used [to set the Tags](playbooks/clouds/build_aws_nodes.yml#L57) when building the nodes.

Then, using the Ansible dynamic inventory for the specific Cloud, the helper `add_{{ cloud_name }}_nodes` [playbooks](playbooks/clouds) create the [Ansible inventory groups](playbooks/clouds/add_nodes_aws.yml#L11) that the rest of the playbooks expect.
- A more elegant solution would have been to use Static Groups of Dynamic Groups as [Ansible recommends](https://docs.ansible.com/ansible/2.6/user_guide/intro_dynamic_inventory.html#static-groups-of-dynamic-groups). However, each Cloud's dynamic inventory has a different syntax for creating the groups, for example AWS uses [`tag_Group_`](playbooks/clouds/add_nodes_aws.yml#L15) while OpenStack uses [`meta-Group_`](playbooks/clouds/add_nodes_openstack.yml#L15) and the helper `add_{{ cloud_name }}_nodes` [playbooks](playbooks/clouds) was the solution to make this work for all Clouds.


## [Parts](id:parts)

Currently, these playbooks are divided into the following parts:
 
1. **(Optional) Build the Cloud nodes**

   Run the `build_cloud.sh` script to build the Cloud nodes. Refer to the Cloud specific INSTALL guides for more information.

2. **Install the cluster**

   Run the `install_cluster.sh` script that will install the HDP and / or HDF cluster using Blueprints while taking care of the necessary prerequisites.


...or, alternatively, run each step separately (also useful for replaying a specific part in case of failure):

1. **(Optional) Build the Cloud nodes**

   Run the `build_cloud.sh` script to build the Cloud nodes. Refer to the Cloud specific INSTALL guides for more information.

2. **Prepare the Cloud nodes**

   Run the `prepare_nodes.sh` script to prepare the nodes.
  
   This installs the required OS packages, applies the recommended OS settings and prepares the database and / or the local MIT-KDC.

3. **Install Ambari**

   Run the `install_ambari.sh` script to install Ambari on the nodes.

   This adds the Ambari repo, installs the Ambari Agent and Server packages and configures the Ambari Server with the required Java and database options.

4. **Configure Ambari**

   Run the `configure_ambari.sh` script to configure Ambari.
  
   This further configures Ambari with some settings, changes admin password and adds the repository information needed by the cluster build.

5. **Apply Blueprint**

   Run the `apply_blueprint.sh` script to install HDP and / or HDF based on an Ambari Blueprint.
  
   This uploads the blueprint to Ambari and applies it. Ambari would then create and install the cluster.

6. **Post Install**

   Run the `post_install.sh` script to execute any actions after the cluster is built.


## [Features](id:features)

### Infrastructure support
- [x] Pre-built infrastructure (using a static inventory file)
- [x] OpenStack nodes
- [ ] OpenStack Block Storage (Cinder)
- [x] AWS nodes (with root EBS only)
- [ ] AWS Block Storage (additional EBS)
- [x] Azure nodes
- [ ] Azure Block Storage (VHDs)
- [x] Google Compute Engine nodes (with root Persistent Disks only)
- [ ] Google Compute Engine Block Storage (additional Persistent Disks)

### OS support
- [x] CentOS/RHEL 6 support
- [x] CentOS/RHEL 7 support
- [x] Ubuntu 14 support
- [x] Ubuntu 16 support
- [x] Amazon Linux 2 AMI support (Ambari 2.7+)
- [x] SUSE Linux Enterprise Server 11 support
- [x] SUSE Linux Enterprise Server 12 support

### Prerequisites done
- [x] Install and start NTP
- [x] Create /etc/hosts mappings
- [x] Set nofile and nproc limits
- [x] Set swappiness
- [x] Disable SELinux
- [x] Disable THP
- [x] Set Ambari repositories
- [x] Install OpenJDK or Oracle JDK
- [x] Install and prepare MySQL
- [x] Install and prepare PostgreSQL
- [x] Install and configure local MIT KDC
- [ ] Partition and mount additional storage

### Cluster build supported features
- [x] Install Ambari Agents and Server
- [x] Configure Ambari Server with OpenJDK or Oracle JDK
- [x] Configure Ambari Server with external database options
- [ ] Configure Ambari Server with SSL
- [x] Configure custom Repositories and specific HDP/HDF versions
- [x] Configure Rack Awareness (static inventory)
- [x] Configure custom Paths (data / logs / metrics / tmp)
- [x] Build HDP clusters
- [x] Build HDF clusters
- [x] Build HDP clusters with HDF nodes
- [x] Build HDP clusters with HDP Search (Solr) addon
- [x] Build clusters with a specific JSON blueprint (static blueprint)
- [x] Build clusters with a generated JSON blueprint (dynamic blueprint based on Jinja2 template and variables)
- [x] Wait for the cluster to be built

### Dynamic blueprint supported features
> The components that will be installed are only those defined in the `blueprint_dynamic` [variable](playbooks/group_vars/all#L161).
> - Supported in this case means all prerequites (databases, passwords, required configs) are taken care of and the component is deployed successfully on the chosen `host_group`.
- [x] HDP Services: `HDFS`, `YARN + MapReduce2`, `Hive`, `HBase`, `Accumulo`, `Oozie`, `ZooKeeper`, `Storm`, `Atlas`, `Kafka`, `Knox`, `Log Search`, `Ranger`, `Ranger KMS`, `SmartSense`, `Spark2`, `Zeppelin`, `Druid`, `Superset`
- [x] HDF Services: `NiFi`, `NiFi Registry`, `Schema Registry`, `Streaming Analytics Manager`, `ZooKeeper`, `Storm`, `Kafka`, `Knox`, `Ranger`, `Log Search`
- [x] HA Configuration: NameNode, ResourceManager, Hive, HBase, Ranger KMS, Druid
- [x] Secure clusters with MIT KDC (Ambari managed)
- [x] Secure clusters with Microsoft AD (Ambari managed)
- [x] Install Ranger and enable all plugins
- [x] Ranger KMS
- [ ] Ranger AD integration
- [ ] Hadoop SSL
- [ ] Hadoop AD integration
- [ ] NiFi SSL
- [ ] NiFi AD integration
- [ ] Basic memory settings tuning
- [ ] Make use of additional storage for HDP workers
- [ ] Make use of additional storage for master services
- [ ] Configure additional storage for NiFi
