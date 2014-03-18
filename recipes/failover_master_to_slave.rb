[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

node.normal_attrs['postgresql']['config'].delete('wal_level')
node.normal_attrs['postgresql']['config'].delete('archive_mode')
node.normal_attrs['postgresql']['config'].delete('max_wal_senders')
node.normal_attrs['postgresql']['config'].delete('archive_command')
node.normal_attrs['postgresql']['config'].delete('hot_standby')

file "#{node['postgresql']['dir']}/archive-replication" do
  action :delete
end

directory node['postgresql']['replication']['backup_dir'] do
  action :delete
  recursive true
end

node.set['postgresql']['replication']['node_type'] = 'slave'
# Set master address to self
node.set['postgresql']['replication']['master_address'] = node['postgresql']['replication']['slave_addresses'][0]
# set slave addresses equal to self
node.set['postgresql']['replication']['slave_addresses'] = [select_ip_attribute(node, node['postgresql']['discovery']['ip_attribute'])]
