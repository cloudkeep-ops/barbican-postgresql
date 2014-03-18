# Configure pg_hba rules used for replication

# Filter out existing replication ACL rules to ensure that dead nodes
# Are removed and only valid nodes remain in pg_hba.conf
pg_hba_rules = node['postgresql']['pg_hba'].select { |rule| rule['db'] != 'replication' }

# Add appropriate rules for pg_hba.conf
if node['postgresql']['replication']['node_type'] == 'master'
  if node['postgresql']['replication']['slave_addresses'].empty?
    pg_hba_rules << {
      :comment => '# Replication ACL',
      :type => 'host',
      :db => 'replication',
      :user => 'repmgr',
      :addr => '0.0.0.0/0',
      :method => 'md5'
    }
  end
  # This is a master node, so update acl list with slave nodes
  node['postgresql']['replication']['slave_addresses'].each do |ipaddress|
    pg_hba_rules << {
      :comment => '# Replication ACL',
      :type => 'host',
      :db => 'replication',
      :user => 'repmgr',
      :addr => "#{ipaddress}/32",
      :method => 'md5'
    }
  end
else
  pg_hba_rules << {
    :comment => '# Replication ACL',
    :type => 'host',
    :db => 'replication',
    :user => 'repmgr',
    :addr => "#{node['postgresql']['replication']['master_address']}/32",
    :method => 'md5'
  }
end

node.set['postgresql']['pg_hba'] = pg_hba_rules
