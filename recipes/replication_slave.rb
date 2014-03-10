node.set['postgresql']['config']['hot_standby'] = 'on'

include_recipe 'postgresql'
include_recipe 'postgresql::server'

# The .pgpass file is used to store the credentials for the repmgr
# user.  These credentials are used by the slave when initiating
# a hot backup from the master
template "#{node['postgresql']['dir']}/../../.pgpass" do
  source 'pgpass.erb'
  user 'postgres'
  group 'postgres'
  mode '0700'
  variables(
    'user' => 'repmgr',
    'password' => node['postgresql']['password']['repmgr']
  )
end

# Render our archive-replication template wich points at master.
# if there is a new master value, this template will notify the
# execute[pg_basebackup] resource to start a hot backup
template "#{node['postgresql']['dir']}/archive-replication" do
  source 'archive-replication.sh.erb'
  owner 'postgres'
  group 'postgres'
  mode '0700'
  variables(
    'ip' => node['postgresql']['replication']['master_address']
  )
  notifies :run, 'execute[pg_basebackup]', :immediately
end

version = node['postgresql']['version']
master_ip = node['postgresql']['replication']['master_address']
backup_dir = node['postgresql']['replication']['backup_dir']
pg_dir = node['postgresql']['dir']

# Initiate a pg_basebackup that will pull down everything from the Master so
# that we can start properly recovering.  if this backup is initiated, the
# slave's postgresql service is notified to stop, and notify
# execute[rsync_backup_data] resource

execute 'pg_basebackup' do
  command "/usr/pgsql-#{version}/bin/pg_basebackup -U repmgr -h #{master_ip} -D #{backup_dir} -P -l failover -c fast -x"
  user 'postgres'
  group 'postgres'
  environment('PGDATA' => node['postgresql']['dir']
  )
  action :nothing
  notifies :stop, 'service[postgresql]', :immediately
  notifies :run, 'execute[rsync_backup_data]', :immediately
end

# Rsync data created by the hot backup from the master node
# and place into the slave's data directory.
execute 'rsync_backup_data' do
  command "rsync -Pavz --exclude pg_log --exclude pg_wal --exclude postgresql.conf --exclude pg_hba* --exclude recovery.* --exclude archive-replication* #{backup_dir}/ #{pg_dir}"
  user 'postgres'
  group 'postgres'
  action :nothing
end

# Drop in our recovery.conf since this is an slave node and
# notify the slave's postgresql service to restart with the
# data backed up form master
template "#{node['postgresql']['dir']}/recovery.conf" do
  source 'recovery.conf.erb'
  owner 'postgres'
  group 'postgres'
  mode '0700'
  variables(
    'ip' => node['postgresql']['replication']['master_address']
  )
  notifies :restart, 'service[postgresql]', :immediately
end
