require 'spec_helper'

describe 'barbican-postgresql::failover_slave_to_master' do
  let(:chef_run) do
    @chef_run = ::ChefSpec::Runner.new
    @chef_run.converge(described_recipe)
  end

  it 'executes pg_clt promote' do
    expect(chef_run).to run_execute('promote-master').with(
      :command => "/usr/pgsql-#{chef_run.node['postgresql']['version']}/bin/pg_ctl promote",
      :user => 'postgres',
      :group => 'postgres',
      :environment => { 'PGDATA' => chef_run.node['postgresql']['dir'] },
      :action => [:run]
    )
  end

  it 'pg_clt promote notifies restart postgres' do
    resource = chef_run.execute('promote-master')
    expect(resource).to notify('service[postgresql]').to(:restart).delayed
  end

  it 'sets node_type as master' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'slave'
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'master'
  end

  it 'runs ruby_block to verify promotion' do
    expect(chef_run).to run_ruby_block('verify promotion')
  end

  it 'sets slave address equal to the old master' do
    master_ip = '192.168.2.12'
    chef_run.node.set['postgresql']['replication']['master_address'] = master_ip
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq [master_ip]
  end

  it 'sets master address to self' do
    chef_run.node.set['postgresql']['discovery']['ip_attribute'] = 'ipaddress'
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq chef_run.node['ipaddress']
  end

end
