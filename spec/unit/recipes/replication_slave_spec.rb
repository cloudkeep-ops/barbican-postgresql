require 'spec_helper'

describe 'barbican-postgresql::replication_slave' do
  let(:chef_run) do
    # a hack because fauxhai does not include 'memory' stanza
    # TODO: stevendgonzales make a pull request to fau
    @chef_run = ::ChefSpec::Runner.new do |node|
      node.set['postgresql']['replication']['node_type'] = 'slave'
      node.set['postgresql']['replication']['master_address'] = '192.168.12.2'
    end
    @chef_run.converge(described_recipe)
  end

  it 'sets master configuration values for replication' do
    expect(chef_run.node['postgresql']['config']['hot_standby']).to eq 'on'
  end

  it 'includes postgres recipes' do
    expect(chef_run).to include_recipe('postgresql')
    expect(chef_run).to include_recipe('postgresql::server')
  end

  it 'creates .pgpass file' do
    expect(chef_run).to create_template("#{chef_run.node['postgresql']['dir']}/../../.pgpass").with(
      :source => 'pgpass.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0700',
      :variables => {
        'user' => 'repmgr',
        'password' => chef_run.node['postgresql']['password']['repmgr']
      }
    )
    expect(chef_run).to render_file("#{chef_run.node['postgresql']['dir']}/../../.pgpass").with_content(
      "*:*:*:repmgr:#{chef_run.node['postgresql']['password']['repmgr']}"
    )
  end

  it 'creates postgres archive-replication command script' do
    expect(chef_run).to create_template("#{chef_run.node['postgresql']['dir']}/archive-replication").with(
      :source => 'archive-replication.sh.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0700',
      :variables => {
        'ip' => chef_run.node['postgresql']['replication']['master_address']
      }
    )
    expect(chef_run).to render_file("#{chef_run.node['postgresql']['dir']}/archive-replication").with_content(
      %Q(rsync -e "ssh -o StrictHostKeyChecking=no" -a ${PGDATA}/$1 postgres@#{chef_run.node['postgresql']['replication']['master_address']}:#{chef_run.node['postgresql']['pg_wal_dir']}
if [ $? != 0 ]
then
  exit 1
fi)
    )
  end

  it 'archive-replication template notifies execute pg_basebackup' do
    resource = chef_run.template("#{chef_run.node['postgresql']['dir']}/archive-replication")
    expect(resource).to notify('execute[pg_basebackup]').to(:run).immediately
  end

  it 'execute pg_basebackup notifies stop postgres' do
    resource = chef_run.execute('pg_basebackup')
    expect(resource).to notify('service[postgresql]').to(:stop).immediately
  end

  it 'execute pg_basebackup notifies run rsync_backup_data' do
    resource = chef_run.execute('pg_basebackup')
    expect(resource).to notify('execute[rsync_backup_data]').to(:run).immediately
  end

  it 'creates recovery.conf' do
    expect(chef_run).to create_template("#{chef_run.node['postgresql']['dir']}/recovery.conf").with(
      :source => 'recovery.conf.erb',
      :owner => 'postgres',
      :group => 'postgres',
      :mode => '0700',
      :variables => {
        'ip' => chef_run.node['postgresql']['replication']['master_address']
      }
    )
    expect(chef_run).to render_file("#{chef_run.node['postgresql']['dir']}/recovery.conf").with_content(
      %Q(standby_mode = 'on'
trigger_file = '/tmp/psql.trigger'
primary_conninfo = 'host=#{chef_run.node['postgresql']['replication']['master_address']} port=5432 user=repmgr'
recovery_target_timeline = 'latest'
# Comment out if we actually need the slave to catch up with its WAL records.
#restore_command = 'cp #{chef_run.node['postgresql']['pg_wal_dir']}/%f %p'
)
    )
  end

  it 'recovery.conf notifies restart postgres' do
    resource = chef_run.template("#{chef_run.node['postgresql']['dir']}/recovery.conf")
    expect(resource).to notify('service[postgresql]').to(:restart).immediately
  end

end
