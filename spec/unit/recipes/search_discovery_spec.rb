require 'spec_helper'

describe 'barbican-postgresql::search_discovery' do
  let(:chef_run) do
    @chef_run = ::ChefSpec::Runner.new
    @chef_run.converge(described_recipe)
  end

  let(:base_pg_hba) do
    @base_pg_hba = [
      {
        'comment' => "# 'local' is for Unix domain socket connections only",
        'type' => 'local',
        'db' => 'all',
        'user' => 'postgres',
        'addr' => nil,
        'method' => 'ident'
      },
      {
        'type' => 'local',
        'db' => 'all',
        'user' => 'all',
        'addr' => nil,
        'method' => 'ident'
      },
      {
        'comment' => '# Open external comms with database',
        'type' => 'host',
        'db' => 'all',
        'user' => 'all',
        'addr' => '0.0.0.0/0',
        'method' => 'md5'
      },
      {
        'comment' => '# Open localhost comms with database',
        'type' => 'host',
        'db' => 'all',
        'user' => 'all',
        'addr' => '127.0.0.1/32',
        'method' => 'trust'
      },
      {
        'comment' => '# Open IPv6 localhost comms with database',
        'type' => 'host',
        'db' => 'all',
        'user' => 'all',
        'addr' => '::1/128',
        'method' => 'md5'
      }
    ]
  end

  it 'only node assigns itself master' do
    chef_run.node.set['postgresql']['replication']['node_type'] = nil
    chef_run.converge(described_recipe)
    expect(chef_run.node['postgresql']['replication']['node_type']).to eq 'master'
    expect(chef_run.node['postgresql']['replication']['master_address']).to eq chef_run.node['ipaddress']
    expect(chef_run.node['postgresql']['replication']['slave_addresses']).to eq []

    # test pg_hba ACL rules
    expected_pg_hba = base_pg_hba
    expected_pg_hba << {
      'comment' => '# Replication ACL',
      'type' => 'host',
      'db' => 'replication',
      'user' => 'repmgr',
      'addr' => '0.0.0.0/0',
      'method' => 'md5'
    }
    expect(chef_run.node['postgresql']['pg_hba']).to eq expected_pg_hba
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

    # test pg_hba ACL rules
    expected_pg_hba = base_pg_hba
    # slave rules should be in reverse order since they are sorted
    [p_slave_2, p_slave_1].each do |slave|
      expected_pg_hba << {
      'comment' => '# Replication ACL',
      'type' => 'host',
      'db' => 'replication',
      'user' => 'repmgr',
      'addr' => "#{slave['ipaddress']}/32",
      'method' => 'md5'
    }
    end

    expect(chef_run.node['postgresql']['pg_hba']).to eq expected_pg_hba
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

    # test pg_hba ACL rules
    expected_pg_hba = base_pg_hba
    expected_pg_hba << {
      'comment' => '# Replication ACL',
      'type' => 'host',
      'db' => 'replication',
      'user' => 'repmgr',
      'addr' => "#{p_master['ipaddress']}/32",
      'method' => 'md5'
    }
    expect(chef_run.node['postgresql']['pg_hba']).to eq expected_pg_hba
  end

end
