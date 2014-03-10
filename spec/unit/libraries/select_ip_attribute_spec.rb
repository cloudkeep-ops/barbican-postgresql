require 'spec_helper'
require './libraries/select_ip_attribute'
include ::Extensions

describe  'select_ip_attribute' do

  # test set up
  ip_address = '192.168.1.1'
  rackspace_private_ip = '10.1.1.1'
  spec_node = ChefSpec::Macros.stub_node('spec_node') do |node|
    node.automatic['ipaddress'] = ip_address
    node.automatic['rackspace'] = { 'private_ip' => rackspace_private_ip }
  end

  it "should eq node['ipaddress'] for nil attribute value" do
    expect(::Extensions.select_ip_attribute(spec_node)).to eq ip_address
  end

  it "should eq node['ipaddress'] for 'ipaddress' attribute value" do
    expect(::Extensions.select_ip_attribute(spec_node, 'ipaddress')).to eq ip_address
  end

  it "should eq node['rackspace']['private_ip']" do
    expect(::Extensions.select_ip_attribute(spec_node, 'rackspace.private_ip')).to eq rackspace_private_ip
  end
end
