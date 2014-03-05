require 'spec_helper'

describe 'barbican-postgresql::replication' do
  let(:chef_run) do
    # a hack because fauxhai does not include 'memory' stanza
    # TODO: stevendgonzales make a pull request to fau
    @chef_run = ::ChefSpec::Runner.new do |node|
      node.set['postgresql']['replication']['node_type'] = 'master'
    end
    @chef_run.converge(described_recipe)
  end

  it 'includes postgres recipes' do
    # expect(chef_run).to include_recipe('postgresql')
    # expect(chef_run).to include_recipe('postgresql::server')
  end

  it 'create pg_wal directory' do
    expect(chef_run).to create_directory("#{chef_run.node['postgresql']['pg_wal_dir']}").with(
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0700',
      :action => [:create]
    )
  end

  it 'create postgres ssh directory' do
    expect(chef_run).to create_directory('/var/lib/pgsql/.ssh/').with(
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0755',
      :action => [:create]
    )
  end

  it 'creates postgres private key' do
    expect(chef_run).to create_template('/var/lib/pgsql/.ssh/id_rsa').with(
      :source => 'id_rsa.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0600'
    )
    expect(chef_run).to render_file('/var/lib/pgsql/.ssh/id_rsa').with_content(
      chef_run.node['postgresql']['postgres']['private_key']
    )
  end

  it 'creates postgres public key' do
    expect(chef_run).to create_template('/var/lib/pgsql/.ssh/id_rsa.pub').with(
      :source => 'id_rsa.pub.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0600'
    )
    expect(chef_run).to render_file('/var/lib/pgsql/.ssh/id_rsa.pub').with_content(
      chef_run.node['postgresql']['postgres']['public_key']
    )
  end

  it 'creates authorized_keys file' do
    expect(chef_run).to create_template('/var/lib/pgsql/.ssh/authorized_keys').with(
      :source => 'authorized_keys.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0600'
    )
    expect(chef_run).to render_file('/var/lib/pgsql/.ssh/authorized_keys').with_content(
      chef_run.node['postgresql']['postgres']['public_key']
    )
  end

  it 'includes replication_master recipe' do
    chef_run.node.set['postgresql']['replication']['initialized'] = true
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::replication_master')
    expect(chef_run).not_to include_recipe('barbican-postgresql::replication_slave')
  end

  it 'does not include replication_master recipe' do
    chef_run.node.set['postgresql']['replication']['initialized'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).not_to include_recipe('barbican-postgresql::replication_master')
  end

  it 'includes replication_slave recipe' do
    chef_run.node.set['postgresql']['replication']['initialized'] = true
    chef_run.node.set['postgresql']['replication']['node_type'] = 'slave'
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::replication_slave')
    expect(chef_run).not_to include_recipe('barbican-postgresql::replication_master')
  end

  it 'does not include replication_slave recipe' do
    chef_run.node.set['postgresql']['replication']['initialized'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).not_to include_recipe('barbican-postgresql::replication_slave')
  end

  it 'recipe sets node to initialized state' do
    expect(chef_run.node['postgresql']['replication']['initialized']).to eq true
  end

end
