version		'0.10.0'

name		'winbind'
maintainer	'City of Burnaby'
maintainer_email 'bishop.clark@burnaby.ca'
license		'BSD2'
description	'Installs/Configures winbind'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
chef_version	'>= 12.1' if respond_to?(:chef_version)

depends		'all-datacenter-attributes'
depends		'ntp'

