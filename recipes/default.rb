#
# Cookbook:: winbind
# Recipe:: default
#
# Copyright:: 2017, City of Burnaby, BSD2

# cheat around the lack of crypto dbags
include_recipe 'all-datacenter-attributes::realm'	# AD centralized settings
include_recipe '::ntp'

# as per
# https://web.archive.org/web/20180927175218/https://access.redhat.com/discussions/903523
# we'll need to work around an unpatched failure in the
# oddjobd/mkhomedir/dbus/systemd fridge-art matrix.  Plan for this to
# change the software list below (and explicitly kill oddjobd to fix
# the behaviour)

#execute "yum clean all ; rm -rf /var/cache/yum/"
# RHEL-RHSM-linked machines are especially frail around repos, so
# let's aggressively kill caches for a while

package %w(samba samba-common samba-client samba-winbind
           samba-winbind-clients )
  .map{|x| x+" < 3.9.9"} do
  action :remove
end

case "#{node[:platform_family]}_#{node[:platform_version].to_i}"
when 'rhel_8'
  package %w[oddjob-mkhomedir samba-winbind-clients samba-winbind adcli authselect-compat] do
    #oddjob samba-common-tools samba-winbind-krb5-locator
    flush_cache [ :before ] unless node['platform_family'] == 'debian'
  end

when 'rhel_7'
package %w(PackageKit samba samba-client samba-common samba-winbind
	samba-winbind-clients oddjob-mkhomedir dbus pam_krb5 krb5-workstation
	adcli authconfig) do
    flush_cache [ :before ] unless node['platform_family'] == 'debian'
end
else
package %w(PackageKit samba4 samba4-client samba4-common
           samba4-winbind samba4-winbind-clients oddjob-mkhomedir dbus
           pam_krb5 krb5-workstation authconfig adcli) do
    flush_cache [ :before ] unless node['platform_family'] == 'debian'
end
end

  authcmd="authconfig " +
    "--enablewinbind --enablewinbindauth --enablewinbindoffline --disablecache " +
    "--enablewinbindusedefaultdomain " +
    "--smbsecurity=ads --smbworkgroup=#{node[:realm][:netbios]} " +
    "--smbrealm=#{node[:realm][:directory_name].upcase} " +
    "--smbservers=#{[* node[:realm][:servers]].join(',')} " +
    "--winbindtemplatehomedir=/home/%U --winbindtemplateshell=/bin/bash " +
    "--krb5realm=#{node[:realm][:directory_name].upcase} " +
    "--disablekrb5kdcdns --disablekrb5realmdns " +
    "--enablelocauthorize --enablepamaccess  " +
    "--smbidmapuid=#{node.read('realm', 'loidrng')||16777216}-#{node.read('realm', 'hiidrng')||33554431} " + 
    "--smbidmapgid=#{node.read('realm', 'loidrng')||16777216}-#{node.read('realm', 'hiidrng')||33554431} " +
    "--enablemkhomedir --updateall"

  file '/etc/.authcmd' do
    content authcmd
    notifies :run, 'execute[authconfig]', :immediate
  end

  execute "authconfig" do
#    command	"#{authcmd} > /etc/.authconfig"
    command	"#{authcmd} || rm -vf /etc/.authcmd"	# Don't fail, keep going
    action	:nothing
#    creates	'/etc/.authconfig'
  end

  ['rm -f /var/lib/samba/winbindd_idmap.tdb', 'service winbind restart'].each do |s|
    #'net cache flush'
    execute s do
      action	:nothing
      subscribes  :run, 'template[/etc/samba/smb.conf]', :delayed
      only_if " [ -f '/etc/krb5.keytab' ] && id #{node[:fqdn].split('.')[0]}$"
    end
  end


  # yes, we still need to patch up the krb5.conf to add in the KDC
  # addresses because authconfig is weak.  grr....
  template '/etc/samba/smb.conf'
  template '/etc/security/pam_winbind.conf'
  include_recipe '::krb5'	# included so we can separate and run ad-hoc :-(

  (node['platform_version'].split('.')[0].to_i >= 7 ? %w(dbus oddjobd) : %w(messagebus oddjobd)).each do |svc|
    service svc do 
      action [ :enable, :start ]
    end
  end
  
  %w(winbind).each do |svc|
    service svc do
      action	[:enable]
    end
  end

  execute 'join ad in winbind' do
    command "net ads join -U #{node.run_state['realm_username']}%#{node.run_state['realm_password']} " +
      (node[:realm][:servers][0] != '*' ? "-S #{node[:realm][:servers][0]} " : '') +
      "createcomputer=#{node[:realm][:wbou]}"
#    sensitive	true
    notifies :restart, 'service[winbind]', :immediately
    not_if " [ -f '/etc/krb5.keytab' ] && id #{node[:fqdn].split('.')[0]}$"
  end

  # this can sometimes fail.  The only solution is to wait for a synch
  # between AD servers, and then try again.
  (node[:realm][:secgroups]||[]).each do |grp|
    execute "add #{node[:fqdn]} to group #{grp}@#{node[:realm][:realm_name]}" do
#      sensitive	true
      command "adcli add-member " + 
        "-D #{node[:realm][:realm_name]} " + 
        "-S #{node[:realm][:servers][0]} " + 
        "-U #{node.run_state['realm_secname']} " + 
        "#{grp} #{node[:fqdn].split('.')[0]}$ " + 
        "<<< '#{node.run_state['realm_secpass']}'"
    not_if "getent group #{grp} | grep -qi '[:,]#{node[:fqdn].split('.')[0]}\\$'"
    end   	# execute
  end		# each

  (node[:realm][:srvtix]||[]).map(&:upcase).each do |srv|
    execute "get service ticket #{srv}/#{node[:fqdn]}@#{node[:realm][:realm_name].upcase}" do
      sensitive	true
      command "net ads keytab " + 
        "add #{srv} " + 
        "-U #{node.run_state['realm_username']}%#{node.run_state['realm_password']}" + 
        "; klist -k"
      not_if "klist -k | grep -qi '#{srv}/#{node[:fqdn]}@#{node[:realm][:realm_name].upcase}'"
    end
  end

