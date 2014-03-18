require 'spec_helper'

describe 'barbican-postgresql::search_discovery' do
  let(:chef_run) do
    @chef_run = ::ChefSpec::Runner.new
    @chef_run.converge(described_recipe)
  end

  it 'only node assigns itself master' do
    chef_run.node.set['postgresql']['replication']['node_type'] = nil
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'master'
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq chef_run.node['ipaddress']
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq []

  end

  it 'master detects slaves in sorted order' do
    # stub out slave nodes
    p_slave_1 = stub_node('postgres-slave-1') do |node|
      node.automatic['ipaddress'] = '192.168.1.40'
      node.set['node_group']['tag'] = 'database'
      node.set['postgresql']['replication']['node_type'] = 'slave'
    end
    p_slave_2 = stub_node('postgres-slave-2') do |node|
      node.automatic['ipaddress'] = '192.168.1.30'
      node.set['node_group']['tag'] = 'database'
      node.set['postgresql']['replication']['node_type'] = 'slave'
    end

    # upload stubbed nodes to chef-zero
    [p_slave_1, p_slave_2].each { |slave| ChefSpec::Server.create_node(slave) }

    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.converge(described_recipe)

    # slave ips should be in reverse order since they are sorted
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq [p_slave_2['ipaddress'], p_slave_1['ipaddress']]
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'master'
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq chef_run.node['ipaddress']

  end

  it 'node detects master and assigns itself slave' do
    # stub out a postgres master node
    p_master = stub_node('postgres-master', :platform => 'centos', :version => '6.5') do |node|
      node.automatic['ipaddress'] = '192.168.12.2'
      node.set['node_group']['tag'] = 'database'
      node.set['postgresql']['replication']['node_type'] = 'master'
    end
    ChefSpec::Server.create_node(p_master)
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq [chef_run.node['ipaddress']]
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'slave'
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq p_master['ipaddress']

  end

end
