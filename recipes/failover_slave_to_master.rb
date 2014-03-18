[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

# Only run pg_ctl if we want to do a failover, no need to do this if we are just
# initializing a new master or slave.
# Promote this node to become the new active master.
execute 'promote-master' do
  command "/usr/pgsql-#{node['postgresql']['version']}/bin/pg_ctl promote"
  user 'postgres'
  group 'postgres'
  environment('PGDATA' => node['postgresql']['dir']
  )
  action :run
  notifies :restart, 'service[postgresql]'
end

# Validate that this postgres node is no longer in recovery mode
ruby_block 'verify promotion' do
  block do
    verify = Mixlib::ShellOut.new("psql -c 'select pg_is_in_recovery()' | grep f", :user => 'postgres', :cwd => '/var/lib/pgsql')
    verify.run_command
    is_slave = verify.stdout.strip

    if is_slave == 'f'
      Chef::Log.info 'postgres is no longer in recovery mode, and can be used as a master'
    else
      fail 'Unable to continue, db is still in recovery mode, and has not been promoted to master' unless is_slave == 'f'
    end
  end
  # allow retries in cas epromotion take slonger to complete
  retries node['postgresql']['db_actions']['retries']
  retry_delay node['postgresql']['db_actions']['retry_delay']
end

# This node has now become master
node.set['postgresql']['replication']['node_type'] = 'master'

# set slave addresses
node.set['postgresql']['replication']['slave_addresses'] = [node['postgresql']['replication']['master_address']]
# Set master address to self
node.set['postgresql']['replication']['master_address'] = select_ip_attribute(node, node['postgresql']['discovery']['ip_attribute'])

include_recipe 'postgresql::server'
