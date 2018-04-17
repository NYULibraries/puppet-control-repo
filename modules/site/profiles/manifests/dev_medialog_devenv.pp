class profiles::dev_medialog_devenv {
  include housekeeping


  package { 'emacs':
    ensure => 'installed',
  }


  include profiles::db_postgresql
  
  postgresql::server::role{'medialog':
    superuser     => true,
    login   =>  true,
    password_hash => 'medialog'
  }

   postgresql::server::db { 'medialog':
     user     => 'medialog',
     password => postgresql_password('medialog', 'medialog'),
   }

   postgresql::server::db { 'medialog-dev':
     user     => 'medialog',
     password => postgresql_password('medialog', 'medialog'),
   }

   postgresql::server::db { 'medialog-test':
     user     => 'medialog',
     password => postgresql_password('medialog', 'medialog'),
   }

  file { "/vagrant/medialog" :
    ensure => directory,
    owner => "vagrant",
    group => "vagrant",
    mode => "0755",
  }

  vcsrepo { '/vagrant/medialog':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/NYU-ACM/medialog.git',
    owner => "vagrant",
    group => "vagrant",
  }

  file { '/vagrant/medialog/config/database.yml':
    ensure => file,
    source => "puppet:///modules/profiles/database.yml",
    owner => "vagrant",
    group => "vagrant",
    mode => "0755",
  }
  
  file { '/vagrant/medialog/config/accounts.yml':
    ensure => file,
    source => "puppet:///modules/profiles/accounts.yml",
    owner => "vagrant",
    group => "vagrant",
    mode => "755",
  }

  file { '/vagrant/medialog/env.sh':
    ensure => file,
    source => "puppet:///modules/profiles/env.sh",
    owner => "vagrant",
    group => "vagrant",
    mode => "755",
  }

  firewall { '100 allow rails port access':
    dport   => 3000,
    proto   => tcp,
    action  => accept,
  }

  class { '::rvm': }

  rvm::system_user { vagrant: ; }

  rvm_system_ruby {
    'ruby-2.3.3':
      ensure      => 'present',
      default_use => true;
  }

  rvm_gem {
  'ruby-2.3.3/bundler':
    ensure  => 'latest',
  }

}
