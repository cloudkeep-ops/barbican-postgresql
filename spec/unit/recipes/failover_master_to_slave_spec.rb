require 'spec_helper'

describe 'barbican-postgresql::failover_master_to_slave' do
  let(:chef_run) do
    @chef_run = ::ChefSpec::Runner.new
    @chef_run.converge(described_recipe)
  end

  it 'delete archive-replication file' do
    expect(chef_run).to delete_file("#{chef_run.node['postgresql']['dir']}/archive-replication")
  end

  it 'delete replication backup directory' do
    expect(chef_run).to delete_directory(chef_run.node['postgresql']['replication']['backup_dir']).with(
      :recursive => true
    )
  end

  it 'deletes master related attributes from config' do
    chef_run.node.set['postgresql']['config']['wal_level'] = 'hot_standby'
    chef_run.node.set['postgresql']['config']['archive_mode'] = 'on'
    chef_run.node.set['postgresql']['config']['max_wal_senders'] = 10
    chef_run.node.set['postgresql']['config']['archive_command'] = "#{chef_run.node['postgresql']['dir']}/archive-replication %p %f"
    chef_run.node.set['postgresql']['config']['hot_standby'] = 'on'
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['config'].include? 'wal_level').to eq false
    expect(chef_run.node['postgresql']['config'].include? 'archive_mode').to eq false
    expect(chef_run.node['postgresql']['config'].include? 'max_wal_senders').to eq false
    expect(chef_run.node['postgresql']['config'].include? 'archive_command').to eq false
    expect(chef_run.node['postgresql']['config'].include? 'hot_standby').to eq false
  end

  it 'sets node_type as slave' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'slave'
  end

  it 'sets master address equal to the old slave' do
    slave_ip = '192.168.2.40'
    chef_run.node.set['postgresql']['replication']['slave_addresses'] = [slave_ip]
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq slave_ip
  end

  it 'sets self as slave address' do
    chef_run.node.set['postgresql']['discovery']['ip_attribute'] = 'ipaddress'
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq [chef_run.node['ipaddress']]
  end

end
