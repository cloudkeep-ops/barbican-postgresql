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

   # uses default queue values of databag not specified
  it 'uses default barbican password' do
    expect(chef_run.node['postgresql']['password']['barbican']).to eq 'barbican'
    expect(chef_run).to create_postgresql_database('barbican_api')
  end

  it 'creates barbican_api database' do
    expect(chef_run).to create_postgresql_database('barbican_api')
  end

  it 'creates barbican db user' do
    expect(chef_run).to create_database_user('barbican')
  end

  it 'grants barbican db user all privelages' do
    expect(chef_run).to grant_postgresql_database_user('barbican')
  end

end
