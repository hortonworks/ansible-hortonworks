ansible-hortonworks
-----------

These Ansible playbooks will build a Hortonworks cluster (either Hortonworks Data Platform or Hortonworks DataFlow) using Ambari Blueprints. For a full list of supported features check [below](#features).

- This includes building the cloud infrastructure and taking care of the prerequisites.

- The aim is to first build the nodes in a Cloud environment, prepare them (OS settings, database, KDC, etc) and then install Ambari and create the cluster using Ambari Blueprints.

- If the infrastructure already exists, it can also use a [static inventory](inventory/static).

- It can use a static blueprint or a [dynamically generated](playbooks/roles/ambari-blueprint/templates/blueprint_dynamic.j2) blueprint based on the components selected in the Ansible [variables file](playbooks/group_vars/ambari-server).


## [Installation](id:installation)

- AWS: See [INSTALL.md](INSTALL_AWS.md) for AWS specific build instructions.
- Azure: See [INSTALL.md](INSTALL_Azure.md) for Azure specific build instructions.
- Google Compute Engine: See [INSTALL.md](INSTALL_GCE.md) for GCE specific build instructions.
- OpenStack: See [INSTALL.md](INSTALL_OpenStack.md) for OpenStack specific build instructions.
- Static inventory: See [INSTALL.md](INSTALL_static.md) for specific build instructions.


## [Requirements](id:requirements)

- Ansible 2.5

- Expects CentOS/RHEL, Ubuntu, Amazon Linux or SLES hosts


## [Description](id:description)

Currently, these playbooks are divided into the following parts:
 
1. **Build the Cloud nodes**

   Run the `build_cloud.sh` script to build the nodes. Refer to the Cloud specific INSTALL guides for more information.

2. **Install the cluster**

   Run the `install_cluster.sh` script that will install the HDP or HDF cluster using Blueprints while taking care of the necessary prerequisites.


...or, alternatively, run each step separately:

1. **Build the Cloud nodes**

   Run the `build_cloud.sh` script to build the nodes. Refer to the Cloud specific INSTALL guides for more information.

2. **Prepare the Cloud nodes**

   Run the `prepare_nodes.sh` script to prepare the nodes.
  
   This installs the required OS packages, applies the recommended OS settings and adds the Ambari repositories.

3. **Install Ambari**

   Run the `install_ambari.sh` script to install Ambari on the nodes.
  
   This installs the Ambari Agent on all nodes and the Ambari Server on the designated node. Ambari Agents are configured to register to the Ambari Server.

4. **Configure Ambari**

   Run the `configure_ambari.sh` script to configure Ambari.
  
   This playbook is used to set the repository URLs in Ambari but will be used for other settings such as the Alert options or the admin user password.

5. **Apply Blueprint**

   Run the `apply_blueprint.sh` script to install HDP or HDF based on an Ambari Blueprint.
  
   This uploads the Ambari Blueprint and Cluster Creation Template and launches a cluster create request to Ambari. It can also wait for the cluster to be built

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
- [ ] Ubuntu 16 support
- [x] Amazon Linux AMI (2016.x, 2017.x and 2018.x) working
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
- [x] Install Ambari Agent and Server with embedded JDK and databases
- [x] Configure Ambari Server with OpenJDK or Oracle JDK
- [x] Configure Ambari Server with advanced database options
- [ ] Configure Ambari Server with SSL
- [x] Configure custom Repositories and specify Versions
- [x] Build HDP clusters
- [x] Build HDF clusters
- [x] Build HDP clusters with HDF nodes
- [x] Build clusters with a specific JSON blueprint (static)
- [x] Build clusters with a generated JSON blueprint (dynamic based on Jinja2 template and variables)
- [x] Wait for the cluster to be built

### Dynamic blueprint supported features
- [x] HA NameNode
- [x] HA ResourceManager
- [x] HA Hive
- [x] HA HBase Master
- [ ] HA Oozie
- [x] Secure clusters with MIT KDC (Ambari managed)
- [x] Secure clusters with Microsoft AD (Ambari managed)
- [x] Install Ranger and enable plugins
- [ ] Ranger AD integration
- [ ] Hadoop SSL
- [ ] Hadoop AD integration
- [ ] NiFi SSL
- [ ] NiFi AD integration
- [ ] Basic memory settings tuning
- [ ] Make use of additional storage for HDP workers
- [ ] Make use of additional storage for master services
- [ ] Configure additional storage for NiFi
