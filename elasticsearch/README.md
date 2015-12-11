# Elasticsearch Chef Cookbook

This cookbook has been converted into a library cookbook as of version 1.0.0,
and supports Chef 12.4.1, 12.3.0, 12.2.1, and higher. It implements support for
CI as well as more modern testing with chefspec and test-kitchen. It no longer
supports some of the more extraneous features such as discovery (use [chef search](http://docs.chef.io/chef_search.html) in your wrapper cookbook) or EBS
device creation (use [the aws cookbook](https://github.com/opscode-cookbooks/aws)).

The previous version of this cookbook may be found in the [0.3.x branch](https://github.com/elastic/cookbook-elasticsearch/tree/0.3.x).

## Default version, download URLs, and checksums
Please consult [attributes/default.rb](attributes/default.rb) for these values.
Both the recipes and resources/providers here source their default values for
Elasticsearch version, download URL, and Checksum from `attributes/default.rb`.

Please take note that you may use `%s` in your URL and this cookbook will use
sprintf/format to insert the version parameter as a string into your
download_url.

You may adjust the node attributes to force this cookbook to use different
default values for all three settings.

## Recipes

### default

The default recipe creates an elasticsearch user and group with the default
options.

## Resources

### elasticsearch_user
Actions: `:create`, `:remove`

Creates a user and group on the system for use by elasticsearch. Here is an
example with many of the default options and default values (all options except
a resource name may be omitted).

Examples:

```
elasticsearch_user 'elasticsearch'
```

```
elasticsearch_user 'elasticsearch' do
  username 'elasticsearch'
  groupname 'elasticsearch'
  homedir '/usr/local/elasticsearch'
  shell '/bin/bash'
  comment 'Elasticsearch User'

  action :create
end
```

### elasticsearch_install
Actions: `:install`, `:remove`

Downloads the elasticsearch software, and unpacks it on the system. There are
currently two ways to install -- `package`, which downloads the appropriate
package from elasticsearch.org and uses the package manager to install it, and
`tarball` which downloads a tarball from elasticsearch.org and unpacks it in
/usr/local on the system. The resource name is not used for anything in
particular. This resource also comes with a `:remove` action which will remove
the package or directory elasticsearch was unpacked into.

You may always specify a download_url and/or download_checksum, and you may
include `%s` which will be replaced by the version parameter you supply.

Please be sure to consult the above section 'Default version, download URLs,
and checksums' as that controls how Elasticsearch version, download URL and
checksum are determined if you omit them.

Examples:

```
elasticsearch_install 'elasticsearch'
```

```
elasticsearch_install 'my_es_installation' do
  type :tarball # type of install
  dir '/usr/local' # where to install

  owner 'elasticsearch' # user and group to install under
  group 'elasticsearch'

  download_url "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.7.2.tar.gz"
  # sha256
  download_checksum "6f81935e270c403681e120ec4395c28b2ddc87e659ff7784608b86beb5223dd2"

  action :install # could be :remove as well
end
```

```
elasticsearch_install 'my_es_installation' do
  type :tarball # type of install
  version '1.7.2'
  action :install # could be :remove as well
end
```

```
elasticsearch_install 'my_es_installation' do
  type :package # type of install
  download_url "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.7.2.deb"
  # sha256
  download_checksum "791fb9f2131be2cf8c1f86ca35e0b912d7155a53f89c2df67467ca2105e77ec2"
  action :install # could be :remove as well
end
```

```
elasticsearch_install 'my_es_installation' do
  type :package # type of install
  version "1.7.2"
  action :install # could be :remove as well
end
```

### elasticsearch_configure
Actions: `:manage`, `:remove`

Configures an elasticsearch instance; creates directories for configuration,
logs, and data. Writes files logging.yml, elasticsearch.in.sh and
elasticsearch.yml.

The main attribute for this resource is `configuration`,
which is a hash of any elasticsearch configuration directives. The
other important attribute is `default_configuration` -- this contains the
minimal set of required defaults.

Note that these are both _not_ a Chef mash, everything must be in a single level
of keys and values. Any settings you pass in configuration will be merged into
(and potentially overwrite) any default settings.

See the examples, [as well as the attributes in the resource file](libraries/resource_configure.rb),
for more.

Examples:

With all defaults -
```
elasticsearch_configure 'elasticsearch'
```

More complicated -
```
elasticsearch_configure 'my_elasticsearch' do
  # if you override one of these, you probably want to override all
  dir '/usr/local/awesome'
  path_conf "/usr/local/awesome/etc/elasticsearch"
  path_data "/usr/local/awesome/var/data/elasticsearch"
  path_logs "/usr/local/awesome/var/log/elasticsearch"

  user 'foo'
  group 'bar'
  logging({:"action" => 'INFO'})

  allocated_memory '123m'
  thread_stack_size '512k'

  env_options '-DFOO=BAR'
  gc_settings <<-CONFIG
                -XX:+UseParNewGC
                -XX:+UseConcMarkSweepGC
                -XX:CMSInitiatingOccupancyFraction=75
                -XX:+UseCMSInitiatingOccupancyOnly
                -XX:+HeapDumpOnOutOfMemoryError
                -XX:+PrintGCDetails
              CONFIG

  configuration ({
    'node.name' => 'crazy'
  })

  action :manage
end
```

### elasticsearch_service
Actions: `:configure`, `:remove`

Writes out a system service configuration of the appropriate type, and enables
it to start on boot. You can override almost all of the relevant settings in
such a way that you may run multiple instances.

```
elasticsearch_service 'elasticsearch'
```

```
elasticsearch_service 'elasticsearch-crazy' do
  node_name 'crazy'
  path_conf '/usr/local/awesome/etc/elasticsearch'
  pid_path '/usr/local/awesome/var/run'
  user 'foo'
  group 'bar'
end
```

### elasticsearch_plugin
Actions: `:install`, `:remove`

Installs or removes a plugin to a given elasticsearch instance and plugin
directory. Please note that there is currently no way to upgrade an existing
plugin using commandline tools, so we haven't exposed that feature here either.
Furthermore, there isn't a way to determine if a plugin is compatible with ES or
even what version it is. So once we install a plugin to a directory, we
generally assume that is the desired one and we don't touch it further.

See https://github.com/elastic/cookbook-elasticsearch/issues/264 for more info.

When running a single instance per machine (VM, etc), it's typically
sufficient to rely on the default value of `plugin_dir`:

```
elasticsearch_plugin 'mobz/elasticsearch-head'
```

To run multiple instances per machine, an explicit `plugin_dir` location
has to be provided:

```
elasticsearch_plugin 'mobz/elasticsearch-head' do
  plugin_dir '/usr/local/awesome/elasticsearch-1.7.2/plugins'
end
```
NB: You [may encounter issues on certain distros](http://blog.backslasher.net/java-ssl-crash.html) with NSS 3.16.1 and OpenJDK 7.x.

## Testing

This cookbook is equipped with both unit tests (chefspec) and integration tests
(test-kitchen and serverspec). It also comes with rubocop and foodcritic tasks
in the supplied Rakefile. Contributions to this cookbook should include tests
for new features or bugfixes, with a preference for unit tests over integration
tests to ensure speedy testing runs. ***All tests and most other commands here
should be run using bundler*** and our standard Gemfile. This ensures that
contributions and changes are made in a standardized way against the same
versions of gems. We recommend installing rubygems-bundler so that bundler is
automatically inserting `bundle exec` in front of commands run in a directory
that contains a Gemfile.

A full test run of all tests and style checks would look like:
```bash
$ bundle exec rake style
$ bundle exec rake spec
$ bundle exec rake integration
$ bundle exec rake destroy
```
The final destroy is intended to clean up any systems that failed a test, and is
mostly useful when running with kitchen drivers for cloud providers, so that no
machines are left orphaned and costing you money.

### Fixtures

This cookbook supplies a few different test fixtures (under `test/fixtures/`)
that can be shared amongst any number of unit or integration tests: cookbooks,
environments, and nodes. Environments and nodes are automatically loaded into
chef-zero for both chefspec tests that run locally and serverspec tests that run
from test-kitchen.

It also contains 'platform data' that can be used to drive unit testing, for
example, you might read `httpd` for some platforms and `apache2` for others,
allowing you to write a single test for the Apache webserver. Unfortunately,
without further modifications to `busser` and `busser-serverspec`, the platform
data will not be available to serverspec tests.

### Style and Best Practices

Rubocop and Foodcritic evaluations may be made by running `rake style`. There
are no overrides for foodcritic rules, however the adjustments to
rubocop are made using the supplied `.rubocop.yml` file and have been documented
by comments within. Most notably, rubocop has been restricted to only apply to
`.rb` files.

Rubocop and foodcritic tests can be executed using `rake style`.

### Unit testing

Unit testing is done using the latest versions of Chefspec. The current default
test layout includes running against all supported platforms, as well as
stubbing data into chef-zero. This allows us to also test against chef search.
As is currently a best practice in the community, we will avoid the use of
chef-solo, but not create barriers to explicitly fail for chef-solo.

Unit tests can be executed using `rake spec`.

### Integration testing

Integration testing is accomplished using the latest versions of test-kitchen
and serverspec. Currently, this cookbook uses the busser-serverspec plugin for
copying serverspec files to the system being tested. There is some debate in the
community about whether this should be done using busser-rspec instead, and each
busser plugin has a slightly different feature set.

While the default test-kitchen configuration uses the vagrant driver, you may
override this using `~/.kitchen/config.yml` or by placing a `.kitchen.local.yml`
in the current directory. This allows you to run these integration tests using
any supported test-kitchen driver (ec2, rackspace, docker, etc).

Integration tests can be executed using `rake integration` or `kitchen test`.

## License

This software is licensed under the Apache 2 license, quoted below.

    Copyright (c) 2015 Elasticsearch <http://www.elasticsearch.org>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
