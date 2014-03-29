default['node_group']['tag'] = 'database'

default['postgresql']['password']['postgres'] = 'postgres' # this is only set for chef-solo
default['postgresql']['password']['barbican'] = 'barbican'

default['postgresql']['db_actions']['retries'] = 3
default['postgresql']['db_actions']['retry_delay'] = 30

normal['postgresql']['enable_pgdg_yum'] = true
normal['postgresql']['version'] = '9.3'
normal['postgresql']['dir'] = '/var/lib/pgsql/9.3/data'
normal['postgresql']['client']['packages'] = %w{ postgresql93 postgresql93-devel}
normal['postgresql']['server']['packages'] = %w{ postgresql93-server }
normal['postgresql']['server']['service_name'] = 'postgresql-9.3'
normal['postgresql']['contrib']['packages'] = %w{ postgresql93-contrib }
normal['postgresql']['config']['listen_addresses'] = '*'

normal['postgresql']['pg_hba'] = [
  {
    :comment => "# 'local' is for Unix domain socket connections only",
    :type => 'local',
    :db => 'all',
    :user => 'postgres',
    :addr => nil,
    :method => 'ident'
  },
  {
    :type => 'local',
    :db => 'all',
    :user => 'all',
    :addr => nil,
    :method => 'ident'
  },
  {
    :comment => '# Open external comms with database',
    :type => 'host',
    :db => 'all',
    :user => 'all',
    :addr => '0.0.0.0/0',
    :method => 'md5'
  },
  {
    :comment => '# Open localhost comms with database',
    :type => 'host',
    :db => 'all',
    :user => 'all',
    :addr => '127.0.0.1/32',
    :method => 'trust'
  },
  {
    :comment => '# Open IPv6 localhost comms with database',
    :type => 'host',
    :db => 'all',
    :user => 'all',
    :addr => '::1/128',
    :method => 'md5'
  }
]
# Attribute to pass to PGTune so that it knows what type of system we're going
# to run.
normal['postgresql']['config_pgtune']['db_type'] = 'oltp'
