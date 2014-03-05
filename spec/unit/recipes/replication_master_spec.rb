require 'spec_helper'

describe 'barbican-postgresql::replication_master' do
  let(:chef_run) do
    # a hack because fauxhai does not include 'memory' stanza
    # TODO: stevendgonzales make a pull request to fau
    @chef_run = ::ChefSpec::Runner.new do |node|
      node.set['postgresql']['replication']['node_type'] = 'master'
    end
    @chef_run.converge(described_recipe)
  end

  it 'sets master configuration values for replication' do
    expect(chef_run.node['postgresql']['config']['wal_level']).to eq 'hot_standby'
    expect(chef_run.node['postgresql']['config']['archive_mode']).to eq 'on'
    expect(chef_run.node['postgresql']['config']['max_wal_senders']).to eq 10
    expect(chef_run.node['postgresql']['config']['archive_command']).to eq "#{chef_run.node['postgresql']['dir']}/archive-replication %p %f"
    expect(chef_run.node['postgresql']['config']['archive_mode']).to eq 'on'
  end

  it 'includes postgres recipes' do
    expect(chef_run).to include_recipe('postgresql')
    expect(chef_run).to include_recipe('postgresql::server')
  end

  it 'includes barbican_db recipe' do
    expect(chef_run).to include_recipe('barbican-postgresql::barbican_db')
  end

  it 'creates repmgr db user' do
    expect(chef_run).to create_database_user('barbican').with(
      :connection => {
        :host => 'localhost',
        :port => chef_run.node['postgresql']['config']['port'],
        :username => 'postgres',
        :password => chef_run.node['postgresql']['password']['postgres']
      },
      :password => chef_run.node['postgresql']['password']['repmgr'],
      :action => [:create],
      :retries => chef_run.node['postgresql']['db_actions']['retries'],
      :retry_delay => chef_run.node['postgresql']['db_actions']['retry_delay']
    )
  end

  it 'executes query to make repmgr a superuser' do
    expect(chef_run).to query_postgresql_database('postgres').with(
      :connection => {
        :host => 'localhost',
        :port => chef_run.node['postgresql']['config']['port'],
        :username => 'postgres',
        :password => chef_run.node['postgresql']['password']['postgres']
      },
      :database_name => 'postgres',
      :sql => 'alter role repmgr with superuser;',
      :action => [:query]
    )
  end

  it 'archive-replication template does not render file if no slaves found' do
    chef_run.node.set['postgresql']['replication']['slave_addresses'] = []
    chef_run.converge(described_recipe)
    expect(chef_run).not_to render_file("#{chef_run.node['postgresql']['dir']}/archive-replication")
  end

  it 'archive-replication template renders file if slaves found' do
    chef_run.node.set['postgresql']['replication']['slave_addresses'] = ['192.168.1.30']
    chef_run.converge(described_recipe)
    expect(chef_run).to render_file("#{chef_run.node['postgresql']['dir']}/archive-replication").with_content(
      %Q(rsync -e "ssh -o StrictHostKeyChecking=no" -a ${PGDATA}/$1 postgres@#{chef_run.node['postgresql']['replication']['slave_addresses'][0]}:#{chef_run.node['postgresql']['pg_wal_dir']}
if [ $? != 0 ]
then
  exit 1
fi)
    )
  end

  it 'archive-replication template notifies postgres' do
    resource = chef_run.template("#{chef_run.node['postgresql']['dir']}/archive-replication")
    expect(resource).to notify('service[postgresql]').to(:restart).immediately
  end

end
