# This recipe uses chef search for node discovery and
# populate atributes used for master_slave replication

[Chef::Recipe, Chef::Resource].each { |l| l.send :include, ::Extensions }

unless Chef::Config[:solo]
  Chef::Log.info 'Performing search'

  # make a single search call to the chef server api, and then select out the master and slave results
  postgres_nodes = search(:node, node['postgresql']['discovery']['search_query'])
  master = postgres_nodes.select { |p_node| p_node['postgresql']['replication']['node_type'] == 'master' }[0] || nil
  slaves = postgres_nodes.select { |p_node| p_node['postgresql']['replication']['node_type'] == 'slave' }

  Chef::Log.info "master result: #{master}"
  Chef::Log.info "slave result: #{slaves}"

  # if I am not already set as a master or slave, figure out who i am
  unless %w(master slave).include? node['postgresql']['replication']['node_type']
    Chef::Log.info 'node_type undefinied'
    # If no master is found, make this node the master
    if master.nil?
      node.set['postgresql']['replication']['node_type'] = 'master'
      Chef::Log.info 'node_type set to master'
    else
      # otherwise, this node is a slave
      node.set['postgresql']['replication']['node_type'] = 'slave'
      Chef::Log.info 'node_type set to slave'
    end
  end

  # update results with current node if necessary
  master = node if (master.nil?) && (node['postgresql']['replication']['node_type'] == 'master')
  slaves << node if (node['postgresql']['replication']['node_type'] == 'slave') &&
    !(slaves.map { |slave| select_ip_attribute(slave, node['postgresql']['discovery']['ip_attribute']) }.include? select_ip_attribute(node, node['postgresql']['discovery']['ip_attribute']))

  # Set master address
  node.set['postgresql']['replication']['master_address'] = select_ip_attribute(master, node['postgresql']['discovery']['ip_attribute'])

  # set slave addresses
  node.set['postgresql']['replication']['slave_addresses'] = (slaves.map { |slave| select_ip_attribute(slave, node['postgresql']['discovery']['ip_attribute']) }).sort

end
