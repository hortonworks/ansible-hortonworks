## HORTONWORKS ANSIBLE PLAYBOOK KERBERIZED
#### This repo is based on the non-official [Ansible Playbook by HORTONWORKS](https://github.com/hortonworks/ansible-hortonworks).

I just add some modification + Use a separated host for KERBEROS..

Before you run the playbook make sure you set the **CLOUD_TO_USE** environment variable to **static**.

 - Full installation : `install-mycluster.sh`

 - Step by Step Installation :

    1.**Prepare the nodes**: `prepare_nodes.sh`

    2.**Install Ambari**: `install_ambari.sh`

    3.**Configure Ambari**: `configure_ambari.sh`

    4.**Install KDC**: `install_kdc.sh`

    5.**Apply Blueprint**: `apply_blueprint.sh`

    6.**Post Install**: `post_install.sh`
	
  - If you want to delete your HORTONWORKS cluster files with :
  
	**Delete HW Cluster** : `delete_cluster.sh`
	
