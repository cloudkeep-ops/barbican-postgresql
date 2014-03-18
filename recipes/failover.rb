# Control recipe for failover operation.

# If this node is a slave, promote to master.  If the node is
# a master, reconfigure as a slave
if node['postgresql']['replication']['node_type'] == 'slave'
  include_recipe 'barbican-postgresql::failover_slave_to_master'
else
  include_recipe 'barbican-postgresql::failover_master_to_slave'
end

# Once failover operations are complete, take node out of failover mode
node.set['postgresql']['replication']['failover'] = false
