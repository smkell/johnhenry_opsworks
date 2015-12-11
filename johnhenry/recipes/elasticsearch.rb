Chef::Log.info("********** Preparing to install and configure elasticsearch! **********")

# search("aws_opsworks_instance").each do |instance|
#   Chef::Log.info("********** The instance's hostname is '#{instance['hostname']}' **********")
#   Chef::Log.info("********** The instance's ID is '#{instance['instance_id']}' **********")
# end

include_recipe 'java::default'
include_recipe 'elasticsearch::default'
