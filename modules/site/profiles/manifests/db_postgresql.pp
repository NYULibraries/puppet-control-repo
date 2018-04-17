  class profiles::db_postgresql {

  	class { 'postgresql::server': }
  	class { 'postgresql::lib::devel': }
  	class { 'postgresql::server::contrib': }

    postgresql::server::role{'vagrant':
    	superuser     => true,
    	login   =>  true,
    	password_hash => 'vagrant'
  	}

     postgresql::server::db { 'vagrant':
     	user     => 'vagrant',
     	password => postgresql_password('vagrant', 'vagrant'),
   	}

   	 firewall { '100 allow mysql port access':
      dport   => 3306,
      proto   => tcp,
      action  => accept,
  	}
}