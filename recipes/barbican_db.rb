
# This connection info is used later in the recipe by the resources to connect to the DB
# Database creation and user calls must be made to localhost.
# Even if postgres is bound to a new listening address it will not have restarted before these
# database and user resources are executed.
#
# Wrapper cookbooks should bind to a selected address as well as localhost
# via node['postgresql']['config']['listen_addresses']
postgresql_connection_info = { :host => 'localhost',
                               :port => node['postgresql']['config']['port'],
                               :username => 'postgres',
                               :password => node['postgresql']['password']['postgres'] }

# Creates a database called 'barbican'
postgresql_database 'barbican_api' do
  connection postgresql_connection_info
  action :create
  retries node['postgresql']['db_actions']['retries']
  retry_delay node['postgresql']['db_actions']['retry_delay']
end

# Creates a user called 'barbican' and sets their password
database_user 'barbican' do
  connection postgresql_connection_info
  password node['postgresql']['password']['barbican']
  provider Chef::Provider::Database::PostgresqlUser
  action :create
  retries node['postgresql']['db_actions']['retries']
  retry_delay node['postgresql']['db_actions']['retry_delay']
end

#  Grants all privileges on 'barbican_api' to user 'barbican'
postgresql_database_user 'barbican' do
  connection postgresql_connection_info
  database_name 'barbican_api'
  privileges [:all]
  action :grant
  retries node['postgresql']['db_actions']['retries']
  retry_delay node['postgresql']['db_actions']['retry_delay']
end
