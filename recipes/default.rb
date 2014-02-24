#
# Cookbook Name:: barbican-postgresql
# Recipe:: default
#
# Copyright (C) 2013 Rackspace, Inc.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'postgresql'
include_recipe 'postgresql::server'
# For use with PGTune.
include_recipe 'postgresql::config_pgtune'
include_recipe 'database::postgresql'

# This connection info is used later in the recipe by the resources to connect to the DB
postgresql_connection_info = { :host => node['postgresql']['config']['listen_addresses'],
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
