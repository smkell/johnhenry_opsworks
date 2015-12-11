Chef::Log.info("********** Preparing to install and configure elasticsearch! **********")

# search("aws_opsworks_instance").each do |instance|
#   Chef::Log.info("********** The instance's hostname is '#{instance['hostname']}' **********")
#   Chef::Log.info("********** The instance's ID is '#{instance['instance_id']}' **********")
# end

include_recipe 'java::default'

elasticsearch_user "elasticsearch"

elasticsearch_install 'elasticsearch' do
  type :package
  version '1.4.4'
end

elasticsearch_configure 'elasticsearch' do 
  dir node['johnhenry']['elasticsearch']['es_home']
  path_conf node['johnhenry']['elasticsearch']['path_conf']
  path_data node['johnhenry']['elasticsearch']['path_data']
  path_logs node['johnhenry']['elasticsearch']['path_logs']

  es_home '/usr/share'

  configuration ({
    'cluster.name' => node['johnhenry']['elasticsearch']['cluster_name'],
    'discovery.zen.ping.multicast.enabled' => false
  })
end

elasticsearch_service 'elasticsearch' do
  path_conf node['johnhenry']['elasticsearch']['path_conf']
  bindir "#{node['johnhenry']['elasticsearch']['es_home']}/elasticsearch/bin"
end

service 'elasticsearch' do 
  action :start
end