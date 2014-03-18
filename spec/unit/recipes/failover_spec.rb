require 'spec_helper'

describe 'barbican-postgresql::failover' do
  let(:chef_run) do
    @chef_run = ::ChefSpec::Runner.new
    @chef_run.converge(described_recipe)
  end

  it 'if node is master demotes to slave' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::failover_master_to_slave')
  end

  it 'if node is slave promotes tp master' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'slave'
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::failover_slave_to_master')
  end

  it 'takes node out of failover mode' do
    chef_run.node.set['postgresql']['replication']['failover'] = true
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['failover']).to eq false
  end

end
