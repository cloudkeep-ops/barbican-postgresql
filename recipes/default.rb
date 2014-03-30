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

include_recipe 'barbican-postgresql::search_discovery' if node['postgresql']['discovery']['enabled'] && !node['postgresql']['replication']['failover']

include_recipe 'barbican-postgresql::failover' if node['postgresql']['replication']['failover']
# We need the below to workaround Build-essential 2.0.0 hard failing an attribute deprecation warning. Not good practice!
node.override['build-essential']['compile_time'] = false
include_recipe 'postgresql'
# For use with PGTune.
include_recipe 'postgresql::config_pgtune'
include_recipe 'database::postgresql'

include_recipe 'barbican-postgresql::replication' if node['postgresql']['replication']['enabled']

include_recipe 'barbican-postgresql::barbican_db' unless node['postgresql']['replication']['enabled']
