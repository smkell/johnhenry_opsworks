require 'serverspec'

# Required by serverspec
set :backend, :exec

describe "Elasticsearch Service" do

  describe user('elasticsearch') do 
    it { should exist }
    it { should belong_to_group 'elasticsearch' }
  end

  describe file('/usr/share/elasticsearch') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/elasticsearch') do 
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/elasticsearch/elasticsearch.yml') do 
    it { should exist }
    it { should be_file }
    its(:content) { should match /cluster\.name\: johnhenry/}
    its(:content) { should match /node\.max_local_storage_nodes\: 1/ }
    its(:content) { should match /path\.data\: \/var\/lib\/elasticsearch/ }
    its(:content) { should match /path\.logs\: \/var\/log\/elasticsearch/ }
  end

  if host_inventory['platform'] == 'ubuntu' 
    describe file('/etc/default/elasticsearch') do 
      it { should exist }
    end
  elsif host_inventory['platform'] == 'rhel'
    describe file('/etc/sysconfig/elasticsearch') do 
      it { should exist }
    end
  end

  describe service('elasticsearch') do 
    it { should be_enabled }
    it { should be_running }
  end
end
