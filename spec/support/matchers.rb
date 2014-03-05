# spec/support/matchers.rb
# creates supporting chefspec matchers for resources that
# did not define them in their orgiginating cookbook
if defined?(ChefSpec)
  def create_postgresql_database(database)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_database, :create, database)
  end

  def query_postgresql_database(database)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_database, :query, database)
  end

  def create_database_user(username)
    ChefSpec::Matchers::ResourceMatcher.new(:database_user, :create, username)
  end

  def grant_postgresql_database_user(username)
    ChefSpec::Matchers::ResourceMatcher.new(:postgresql_database_user, :grant, username)
  end
end
