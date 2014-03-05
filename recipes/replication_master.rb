# Set wal_level, max_wal_senders, and archive_mode. These are needed to enable WAL shipping.
node.set['postgresql']['config']['wal_level'] = 'hot_standby'
node.set['postgresql']['config']['archive_mode'] = 'on'
# Set max_wal_senders to a sane value.
node.set['postgresql']['config']['max_wal_senders'] = 10
# Set archive_command.
node.set['postgresql']['config']['archive_command'] = "#{node['postgresql']['dir']}/archive-replication %p %f"
node.set['postgresql']['config']['hot_standby'] = 'on'

include_recipe 'postgresql'
include_recipe 'postgresql::server'

include_recipe 'barbican-postgresql::barbican_db'

Chef::Log.info 'Configuring node as replication master'

postgresql_connection_info = { :host => 'localhost',
                               :port => node['postgresql']['config']['port'],
                               :username => 'postgres',
                               :password => node['postgresql']['password']['postgres'] }

# Creates a user called 'repmgr' and sets their password
database_user 'repmgr' do
  connection postgresql_connection_info
  password node['postgresql']['password']['repmgr']
  provider Chef::Provider::Database::PostgresqlUser
  action :create
  retries node['postgresql']['db_actions']['retries']
  retry_delay node['postgresql']['db_actions']['retry_delay']
end

# Alter the Repmgr role to include Replication, although seems Superuser is now synonymous for this privilege in 9.2.
postgresql_database 'postgres' do
  connection postgresql_connection_info
  database_name 'postgres'
  sql 'alter role repmgr with superuser;'
  action :query
end

# Time to place our archive-replication script.
template "#{node['postgresql']['dir']}/archive-replication" do
  source 'archive-replication.sh.erb'
  not_if { node['postgresql']['replication']['slave_addresses'].empty? }
  owner 'postgres'
  group 'postgres'
  mode '0700'
  variables(
  'ip' => node['postgresql']['replication']['slave_addresses'][0]
  )
  notifies :restart, 'service[postgresql]', :immediately
end
