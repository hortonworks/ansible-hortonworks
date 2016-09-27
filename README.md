ansible-hdp
-----------

These Ansible playbooks will build a Hortonworks Data Platform cluster.

The aim is to first build the nodes in a Cloud environment, prepare them (OS settings, etc) and then install Ambari and create the cluster using Ambari Blueprints.


## [Installation] (id:installation)

- Azure: See [INSTALL.md](../master/INSTALL_Azure.md) for Azure specific build instructions.
- OpenStack: See [INSTALL.md](../master/INSTALL_OpenStack.md) for OpenStack specific build instructions.


## [Requirements] (id:requirements)

- Ansible >= 2.1.1

- Expects CentOS/RHEL 7 or Ubuntu 14 hosts


## [Description] (id:description)

Currently, these playbooks are divided into the following parts:
 
1. Build the Cloud nodes

  Run the Cloud specific `build_` script to build the nodes. Refer to the Cloud specific INSTALL guides for more information.

1. Prepare the Cloud nodes

  Run the Cloud specific `prepare_nodes_` script to prepare the nodes.
  
  This installs the required OS packages, applies the recommended OS settings and adds the Ambari repositories.

1. Install Ambari

  Run the Cloud specific `install_ambari_` script to install Ambari on the nodes.
  
  This installs the Ambari Agent on all nodes and the Ambari Server on the designated node. Ambari Agents are configured to register to the Ambari Server.
