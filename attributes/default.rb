
include_attribute 'all-datacenter-attributes'

cookbook_name = 'winbind'
recipe_name = 'default'

include_attribute 'all-datacenter-attributes::realm'	# AD centralized settings

