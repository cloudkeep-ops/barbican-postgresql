require 'spec_helper'

describe 'barbican-postgresql::default' do
  let(:chef_run) do
    # a hack because fauxhai does not include 'memory' stanza
    # TODO: stevendgonzales make a pull request to fau
    @chef_run = ::ChefSpec::Runner.new do |node|
      node.set['memory']['total'] = '49416564kB'
    end
    @chef_run.converge(described_recipe)
  end

  it 'includes search discovery if enabled' do
    chef_run.node.set['postgresql']['discovery']['enabled'] = true
    chef_run.node.set['postgresql']['replication']['failover'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::search_discovery')
  end

  it 'does not include search discovery if disabled' do
    chef_run.node.set['postgresql']['discovery']['enabled'] = false
    chef_run.node.set['postgresql']['replication']['failover'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).to_not include_recipe('barbican-postgresql::search_discovery')
  end

  it 'does not include search discovery failover is enabled' do
    chef_run.node.set['postgresql']['discovery']['enabled'] = true
    chef_run.node.set['postgresql']['replication']['failover'] = true
    chef_run.converge(described_recipe)
    expect(chef_run).to_not include_recipe('barbican-postgresql::search_discovery')
  end

  it 'includes failover if enabled' do
    chef_run.node.set['postgresql']['replication']['failover'] = true
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::failover')
  end

  it 'does not include failover if disabled' do
    chef_run.node.set['postgresql']['replication']['failover'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).not_to include_recipe('barbican-postgresql::failover')
  end

  it 'includes postgres recipes' do
    expect(chef_run).to include_recipe('postgresql')
    expect(chef_run).to include_recipe('postgresql::server')
    expect(chef_run).to include_recipe('postgresql::config_pgtune')
    expect(chef_run).to include_recipe('postgresql::server')
    expect(chef_run).to include_recipe('database::postgresql')
  end

  it 'includes replication if enabled' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.node.set['postgresql']['replication']['enabled'] = true
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::replication')
  end

  it 'does not include replication if disabled' do
    chef_run.node.set['postgresql']['replication']['enabled'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).to_not include_recipe('barbican-postgresql::replication')
  end

  it 'includes barbicandb if replication disabled' do
    chef_run.node.set['postgresql']['replication']['enabled'] = false
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('barbican-postgresql::barbican_db')
  end

  it 'does not include barbicandb if replication enabled' do
    chef_run.node.set['postgresql']['replication']['node_type'] = 'master'
    chef_run.node.set['postgresql']['replication']['enabled'] = true
    chef_run.converge(described_recipe)
    expect(chef_run).to_not include_recipe('barbican-postgresql::barbican_db')
  end

end
