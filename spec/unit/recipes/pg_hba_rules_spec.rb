require 'spec_helper'

describe 'barbican-postgresql::pg_hba_rules' do
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

  it 'master loads slave replication rules' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.node.set['postgresql']['replication']['slave_addresses'] = ['192.168.1.30', '192.168.1.40']
    chef_run.converge(described_recipe)
    # test pg_hba ACL rules
    expected_pg_hba = base_pg_hba
    # slave rules should be in reverse order since they are sorted
    chef_run.node['postgresql']['replication']['slave_addresses'].each do |slave|
      expected_pg_hba << {
      'comment' => '# Replication ACL',
      'type' => 'host',
      'db' => 'replication',
      'user' => 'repmgr',
      'addr' => "#{slave}/32",
      'method' => 'md5'
      }
    end

    expect(chef_run.node['postgresql']['pg_hba']).to eq expected_pg_hba
  end

  it 'slave assigns rule for master' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'slave'
    chef_run.node.set['postgresql']['replication']['master_address'] = '192.168.2.12'
    chef_run.converge(described_recipe)
    # test pg_hba ACL rules
    expected_pg_hba = base_pg_hba
    expected_pg_hba << {
      'comment' => '# Replication ACL',
      'type' => 'host',
      'db' => 'replication',
      'user' => 'repmgr',
      'addr' => "#{chef_run.node['postgresql']['replication']['master_address']}/32",
      'method' => 'md5'
    }
    expect(chef_run.node['postgresql']['pg_hba']).to eq expected_pg_hba
  end
end
