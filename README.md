ansible-hdp
-----------

These Ansible playbooks will build a Hortonworks cluster (either Hortonworks Data Platform or Hortonworks DataFlow) using Ambari Blueprints.

This includes building the cloud infrastructure and taking care of the prerequisites.

The aim is to first build the nodes in a Cloud environment, prepare them (OS settings, etc) and then install Ambari and create the cluster using Ambari Blueprints.


## [Installation] (id:installation)

- AWS: See [INSTALL.md](../master/INSTALL_AWS.md) for AWS specific build instructions.
- Azure: See [INSTALL.md](../master/INSTALL_Azure.md) for Azure specific build instructions.
- Google Compute Engine: See [INSTALL.md](../master/INSTALL_GCE.md) for GCE specific build instructions.
- OpenStack: See [INSTALL.md](../master/INSTALL_OpenStack.md) for OpenStack specific build instructions.


## [Requirements] (id:requirements)

- Ansible >= 2.2.1

- Expects CentOS/RHEL 7 or Ubuntu 14 hosts (also supports Amazon Linux AMI)


## [Description] (id:description)

Currently, these playbooks are divided into the following parts:
 
1. Build the Cloud nodes

  Run the `build_cloud.sh` script to build the nodes. Refer to the Cloud specific INSTALL guides for more information.

1. Install the cluster

  Run the `install_cluster.sh` script that will install the HDP or HDF cluster using Blueprints while taking care of the necessary prerequisites.


...or, alternatively, run each step separately:

1. Build the Cloud nodes

  Run the `build_cloud.sh` script to build the nodes. Refer to the Cloud specific INSTALL guides for more information.

1. Prepare the Cloud nodes

  Run the `prepare_nodes.sh` script to prepare the nodes.
  
  This installs the required OS packages, applies the recommended OS settings and adds the Ambari repositories.

1. Install Ambari

  Run the `install_ambari.sh` script to install Ambari on the nodes.
  
  This installs the Ambari Agent on all nodes and the Ambari Server on the designated node. Ambari Agents are configured to register to the Ambari Server.

1. Configure Ambari

  Run the `configure_ambari.sh` script to configure Ambari.
  
  This playbook is used to set the repository URLs in Ambari but will be used for other settings such as the Alert options or the admin user password.

1. Apply Blueprint

  Run the `apply_blueprint.sh` script to install HDP or HDF based on an Ambari Blueprint.
  
  This uploads the Ambari Blueprint and Cluster Creation Template and launches a cluster create request to Ambari. It can also wait for the cluster to be built
