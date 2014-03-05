# module Extensions are library useful functions for use in recipes
module Extensions
  # Allows a user to specifiy the node attribute used to determine the ip_address.
  # Converts a string in the form of foo.bar.baz' and retrieves the attribute
  # value at node['foo']['bar']['baz']

  def select_ip_attribute(node, attribute = nil)
    if attribute
      # iterates through keys seperated by '.', eg
      # 'foo.bar.baz' => node['foo']['bar']['baz']
      keys = attribute.split('.')
      value = node
      keys.each { |key| value = value[key] }
      Chef::Log.debug("Selected attribute: #{attribute.inspect} for node: #{node.name.inspect} with value: #{value.inspect}")
      value
    else
      Chef::Log.debug("Selected attribute: \"ipaddress\" for node: #{node.name.inspect} with value: #{node['ipaddress'].inspect}")
      node['ipaddress']
    end
  end
end
