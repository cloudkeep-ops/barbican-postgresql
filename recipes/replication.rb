# This recipe controls the actions for configuring postgres
# master/slave replication.
#
# Master and slave determinations can be specified by setting the
# node['postgresql']['replication']['node_type'] equal to 'master' or 'slave.'
#
# The addresses of master and slave servers are specified in
# node['postgresql']['replication']['master_address'] for the msater node
# and node['postgresql']['replication']['slave_adresses'] contains
# a list of slave addresses.
#
# Postgres host based authentication file must also be updated for each node by
# updating the node['postgresql']['pg_hba'] attribute
#
# Alternatively, the barbican-postgresql::search_discovery recipe can be used to
# populate all of the above attributes automatically.
#
# While it is possible to only setup streaming replication without WAL
# shipping, this is not recommended due to having to bootstrap the server again
# if the slave falls too far behind. If WAL shipping and streaming replication
# are configured concurrently however, this is not an issue since the slave can
# just fall back on the shipped WAL records to catch up instead.

unless %w(master slave).include? node['postgresql']['replication']['node_type']
  Chef::Log.fatal "node['postgresql']['replication']['node_type'] must be set to either master or slave"
  fail
end

Chef::Log.info 'Configuring postgresql replication'

# Create pg_wal directory for storing of WAL records
directory node['postgresql']['pg_wal_dir'] do
  owner 'postgres'
  group 'postgres'
  mode '0700'
  action :create
end

# Create pg_wal directory for storing of WAL records
directory '/var/lib/pgsql/.ssh/' do
  owner 'postgres'
  group 'postgres'
  mode '0755'
  action :create
end

template '/var/lib/pgsql/.ssh/id_rsa' do
  source 'id_rsa.erb'
  owner 'postgres'
  group 'postgres'
  mode '0600'
end

template '/var/lib/pgsql/.ssh/id_rsa.pub' do
  source 'id_rsa.pub.erb'
  owner 'postgres'
  group 'postgres'
  mode '0600'
end

template '/var/lib/pgsql/.ssh/authorized_keys' do
  source 'authorized_keys.erb'
  owner 'postgres'
  group 'postgres'
  mode '0600'
end

if node['postgresql']['replication']['initialized']
  include_recipe 'barbican-postgresql::replication_master' if node['postgresql']['replication']['node_type'] == 'master'
  include_recipe 'barbican-postgresql::replication_slave' if node['postgresql']['replication']['node_type'] == 'slave'
else
  node.set['postgresql']['replication']['initialized'] = true
end
