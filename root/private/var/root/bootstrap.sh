#!/usr/bin/env bash
# https://github.com/cgerke

# Chef
chef_node=$(scutil --get HostName)
curl -#L https://opscode.com/chef/install.sh | sudo bash
chflags -h hidden /opt
# ~/.chef/knife.rb
cd ~ || exit 1
/opt/chef/bin/knife bootstrap 127.0.0.1 -N "${chef_node}" -V -y
/opt/chef/bin/knife node run_list add "${chef_node}" "role[default]"
/opt/chef/bin/knife node run_list add "${chef_node}" "cpe_init"
/opt/chef/bin/chef-client

exit 0
