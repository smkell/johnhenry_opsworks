Chef::Log.info("********** Preparing to install and configure elasticsearch! **********")

# search("aws_opsworks_instance").each do |instance|
#   Chef::Log.info("********** The instance's hostname is '#{instance['hostname']}' **********")
#   Chef::Log.info("********** The instance's ID is '#{instance['instance_id']}' **********")
# end

include_recipe 'java'

elasticsearch_user "elasticsearch"

elasticsearch_install 'elasticsearch'

elasticsearch_configure 'elasticsearch' do 
  path_data package: node['johnhenry']['elasticsearch']['path_data']
  configuration ({
    'network.host' => '0.0.0.0',
    'cluster.name' => node['johnhenry']['elasticsearch']['cluster_name'],
  })
end

elasticsearch_service 'elasticsearch'

service 'elasticsearch' do 
  action :start
end
