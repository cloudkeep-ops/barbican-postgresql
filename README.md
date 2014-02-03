## barbican-postgresql cookbook

Installs postgresql for use with Barbican.  Creates Barbican database and adds db users.  Environment/deployment specific configurations should be set by wrapping this cookbook.

## Requirements

Requires Cookbook postgresql v3.2.0 for use with CentOS

## Attributes

* `default['postgresql']['password']['barbican']` - password for barbican user
* `default['postgresql']['password']['postgres']` - password for postgres user

These attributes should probably be set in a wrapper cookbook using a databag.  For example:

```ruby
postgres_passwords = data_bag_item("#{node.chef_environment}", 'postgresql')
node.set['postgresql']['password']['postgres'] = postgres_passwords['password']['postgres']
node.set['postgresql']['password']['barbican'] = postgres_passwords['password']['barbican']
```

## Recipes

default.rb
----------
Install postgress 9.2, creates a Barbican databse, and sets the passwords for postgres and barbican db users.

"run_list": [
  "recipe[barbican-postgresql]"
]

## Author

Author:: Rackspace, Inc. (<cloudkeep@googlegroups.com>)
