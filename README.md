## barbican-postgresql cookbook

Installs postgresql for use with Barbican.  Creates Barbican database and adds db users.  Environment/deployment specific configurations should be set by wrapping this cookbook.

## Requirements

Requires Cookbook postgresql v3.2.0 for use with CentOS

## Attributes

* `default['postgresql']['password']['barbican']` - password for barbican user
* `default['postgresql']['password']['postgres']` - password for postgres user

These attributes should probably be set in a wrapper cookbook using a databag.  For example:

```ruby
postgres_passwords = data_bag_item("#{node.chef_environment}", 'postgresql')
node.set['postgresql']['password']['postgres'] = postgres_passwords['password']['postgres']
node.set['postgresql']['password']['barbican'] = postgres_passwords['password']['barbican']
```

* `default['postgresql']['discovery']['enabled']` - enable the search discovery recipe for replication
* `default['postgresql']['discovery']['search_query']` - the chef server node query used to discover postgres nodes
* `default['postgresql']['discovery']['ip_attribute']` - the node attribute that identifies the ipaddress for discovered nodes.  This allows you to specify items like 'rackspace.private_ip' which tells the discovery recipe to use node['rackspace']['private_ip'].  A nil value uses node['ipaddress'] by default.  

* `default['postgresql']['replication']['initialized']` - true||false indicates whether the node needs an initialization run to setup ssh keys and communication to prepare for replication 
* `default['postgresql']['replication']['enabled']` - whether or not to setup replication
* `default['postgresql']['password']['repmgr']` - password for replication user
* `default['postgresql']['replication']['node_type']` - master || slave #you may leave nil if using search_discovery recipe
* `default['postgresql']['replication']['backup_dir'] ` - the directory where the slave stores the hot backup taken form master
* `default['postgresql']['replication']['master_address']` - address of master node
* `default['postgresql']['replication']['slave_addresses']` - address of slave nodes
* `default['postgresql']['pg_wal_dir']` - The directory where postgres write ahead logs are stored

* `default['postgresql']['postgres']['private_key']` - private key used by the postgres user for rsync actions between master and slave nodes
* `default['postgresql']['postgres']['public_key']` - the matching public key

The private and public keys default to use the "vagrant insecure key." This key pair is insecure and should only be used for testing. The attributes shoudl probably be set in a wrapper cookbook using a databag.  For example:

```ruby
postgres_passwords = data_bag_item("#{node.chef_environment}", 'postgresql')
node.set['postgresql']['postgres']['private_key'] = postgres_passwords['postgres']['private_key']
node.set['postgresql']['postgres']['public_key'] = postgres_passwords['postgres']['public_key']
```

## Recipes

default.rb
----------
Install postgress 9.3, creates a Barbican databse, and sets the passwords for postgres and barbican db users.  May call search discovery and replication recipes if node['postgresql']['discovery']['enabled'] and node['postgresql']['replication']['enabled'] are set to true

"run_list": [
  "recipe[barbican-postgresql]"
]

barbican_db.rb
---------------
Create the barbican_api database and create barbican database users.


### Replication Recipes

The below descriptions outline the details of actions performed in each replication recipe.  These recipes may all be configured and launched from the default recipe.  If you want to enable automatic node discovery and master/slave replication, you may follow these steps:

1.  Set node attributes
  Set node['postgresql']['discovery']['enabled'] = true to enable search dicovery
  Set node['postgresql']['discovery']['search_query'] to use a custom query value for a chef_search to discover other postgres nodes.
  Set node['postgresql']['discovery']['ip_attribute'] if you want to use an ip address other than node['ipaddress']
  Set node['postgresql']['replication']['enabled'] = true to enable replication

2.  Add the default recipe to your node's run list.  The default rcipe will call all necessary babrican and replication recipes.

  "run_list": [
    "recipe[barbican-postgresql]"
  ]

3.  Run the chef client once on both your master and slave node to perform intiialization steps.  The first node you run the chef-client on will be set as master and subsequent nodes as slaves.  

4.  Re-run chef-client on master node.  This will initialize the barbican database and start archiving.

5.  Re-run chef-client on slave.  This will start the replication to the slave node and allow the node to accept read-only connections.


search_discovery.rb
--------------------
Use a search query specified in node['postgresql']['discovery']['search_query'] to query chef server and retreive all other postgres nodes.  Populate the node['postgresql']['replication']['master_address'] and node['postgresql']['replication']['slave_addresses'] using the ip attribute set in node['postgresql']['discovery']['ip_attribute'].

This recipe will be called by the default recipe by setting node['postgresql']['discovery']['enabled'] = true.

replication.rb
---------------
Prep the node for replication.  Set up pg_wal directories for stroring write ahead logs, and set up ssh keys for communication between nodes.  The first pass of this recipe completes by setting the nodes state to initialized.  After the node has been initialized a subsequent run will call either the replication_master or replication_slave recipe to complete configuration of replication.

replication_master.rb
----------------------
Called by the replication recipe after initialization.  Configure the master node for replication.  Create the db user for replication, set the write ahead log level to hot_standby, and configure archiving using rsync.

replication_slave.rb
----------------------
Called by the replication recipe after initialization.  Sets up pgpass file for replication user to communicate with master, performs a pg_basebackup from master, recovers from master with wal stream reading enabled, configures recovery.conf for use of slave must failover to master.

## Author

Author:: Rackspace, Inc. (<cloudkeep@googlegroups.com>)
