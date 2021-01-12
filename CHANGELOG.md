## change log for winbind
0.7.0
	bc - move 'stringvar' to [* stringorarrayvar ][0] to handle the
	     array-of-strings case
	bc - ugly case statement to handle el8 fixating on chrony over ntp
	bc - also add in a crappy chrony baseline config for now
	bc - move the cache-clearing into the package statements instead
	     so it'll morph to f'n DNF equivalents when executed by el8
	     machines
	bc - create ad-hoc distro_ver case statement - uch - to move
	     package lists to more complicated recipe code instead of just
	     cleaning it up into attributes.  \sigh.
	bc - change authcommand so it won't interrupt post-clone
	     instantiation, given the auth can be re-run later.
	bc - add cheap customization in some terms in krb5.conf

0.6.0
	bc - move the sssd/winbind decision out

0.5.2
	bc - DISABLE krb5 in security/pam_winbind.conf for now for RHEL6

0.5.1
	New SMB.conf format:
	https://access.redhat.com/sites/default/files/attachments/rhel-ad-integration-deployment-guidelines-v1.5.pdf
	 - idmap_rid
	 - evade number collision/nonuniformity
	 - ensure winbindd_idmap.tdb nuked if the smb.conf changes

	 - check that domain and search is set right in resolv.conf
	 - recommends HOSTNAME = fqdn

0.5.0
	bc - change restart disco for RHEL7/dbus
	bc - sensitive all ops
	bc - ensure smb.conf interfaces set for primary interface

0.4.0
	bc - ensure chrony is removed after adding ntpd support.
	bc - don't write * into krb.conf

0.3.0
	bc - ensure authconfig is installed where required.

0.2.0
	add in 3p ntp instead of local wheel reinvention
