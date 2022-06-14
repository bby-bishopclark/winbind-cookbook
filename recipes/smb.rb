#
# Cookbook:: winbind
# Recipe:: default
#
# Copyright:: 2017, City of Burnaby, BSD2

# cheat around the lack of crypto dbags
template '/etc/samba/smb.conf'
