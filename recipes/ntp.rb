#
# Cookbook:: winbind
# Recipe:: ntp
#
# Copyright:: 2017, City of Burnaby, BSD2

include_recipe 'all-datacenter-attributes::ntp'		# centralized NTP settings

case true	# what a cop-out
when  node['platform_family'] == 'rhel' && node['platform_version'].to_i > 7 
# if machine is chrony-codependent, set our addiction to suit
# install chrony and config
  package 'chrony'

  file '/etc/chrony.conf' do
    content <<-EOC
#{[*node.read(*%w(ntp servers))].map{|x| "pool #{x}"}.join("\n")}
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOC
  end

  service 'chrony' do
    service_name 'chronyd'
    supports restart: true, status: true, reload: true
    action %i(start enable)
  end

# remove ntp
  package 'ntp' do
    action	:remove
  end

else
  include_recipe 'ntp'					# NTP server list
  
package %w(chrony) do
  action	:remove
end
end
