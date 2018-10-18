ansible-hortonworks roles
-----------

The following roles are being used throughout this project:


## common
This role is applied to all nodes and it's responsible with preparing the OS specific prerequisites:
- installs the required OS packages
- installs Java
- starts NTP
- adds all nodes to /etc/hosts (if requested using the `external_dns` variable)
- sets ulimits
- sets swappiness
- stops the firewall service (if requested using the `disable_firewall` variable)
- disables selinux
- disables THP
- configures tuned (if needed)
- creates the http secret key (if Kerberos is enabled)

## database
This role is applied to database nodes (by default this is the `ambari-server` group) and it's responsible with installing the database packages and setting up the databases and users as per the [documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.7.0.0/administering-ambari/content/amb_using_existing_or_installing_default_databases.html).

The role will only execute if the `database` variable is not `embedded` and `database_options.external_hostname` is empty, as otherwise it's implied the database prerequisites are being taken care of outside these playbooks.

It also won't do much when using a static blueprint as most helper variables are not being set with a static blueprint: when using a static blueprint, the database prerequisites need to be done before running these playbooks.

## krb5-client
This role is applied to all nodes when the `security` variable is set to `mit-kdc`.

It installs the Kerberos client packages and sets a basic `/etc/krb5.conf` file.

## mit-kdc
This role is applied to Kerberos server nodes (by default this is the `ambari-server` group) and it's responsible with installing the MIT KDC packages and setting up the KDC as per the [documentation](https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.2.2/bk_ambari-security/content/optional_install_a_new_mit_kdc.html).

The role will only execute if `security` is set to `mit-kdc` and `security_options.external_hostname` is empty, as otherwise it's implied there is already a KDC or AD running and configured.

## ambari-repo
This role is executed as a [dependency](ambari-agent/meta/main.yml) of the `ambari-agent` and `ambari-server` roles.

It sets up the Ambari repositories.

## ambari-agent
This role is applied to all nodes and it's responsible with installing, configuring and starting the Ambari Agents.

## ambari-server
This role is applied to the Ambari Server node (by default this is the `ambari-server` group) and it's responsible with installing, setting up (with the required Java and database options) and starting the Ambari Server.

## ambari-config
This role is applied to the Ambari Server node (by default this is the `ambari-server` group) and it's responsible with configuring the Ambari Server:
- sets up several settings (accepts GPL license, home folder creation)
- installs any required mpacks (like HDF, HDP Search)
- registers the cluster repository information to Ambari
- at the end it checks that all Ambari Agents are registered to the Server

## ambari-blueprint
This role is applied to the Ambari Server node (by default this is the `ambari-server` group) and it's responsible with applying a blueprint to the Ambari Server.

If using the `blueprint_dynamic` option, it generates the blueprint using a [Jinja2 template](ambari-blueprint/templates/blueprint_dynamic.j2).

If using a static blueprint, it uploads that file as a blueprint. It still uses the [template](https://docs.ansible.com/ansible/latest/modules/template_module.html) module so this static blueprint can include [Jinja2 variables](ambari-blueprint/files/blueprint_hdfs_only.j2#L56) if needed.

Then it generates the [Cluster Creation Template](https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-ClusterCreationTemplateStructure) which is a [Jinja2 template](ambari-blueprint/templates/cluster_template.j2) irrespective of the blueprint type (this can be changed using the `cluster_template_file` variable).

Depending on the `wait` variable, it will wait for the cluster to be fully deployed by Ambari.

At the end of this role, the HDP/HDF/HDP Search cluster should be fully installed.

## post-install
This role is applied to all nodes and it's responsible with doing any work after the installation of the cluster.

Currently it fixes a file ownership that can only be done after the cluster is built as it requires the `hdfs` user to be present.
