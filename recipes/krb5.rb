#
# Cookbook:: winbind
# Recipe:: krb5
#
# Copyright:: 2017, City of Burnaby, BSD2

# cheat around the lack of crypto dbags
include_recipe 'all-datacenter-attributes::realm'	# AD centralized settings

template '/etc/krb5.conf'
