# Class: tct::install
# ===========================
#
# Full description of class tct here.
#
#
# Examples
# --------
#
#
# Authors
# -------
#
# Flannon Jackson <flannon@nyu.edu>
#
# Copyright
# ---------
#
# Copyright 2017 Your name here, unless otherwise noted.
#
class tct::install (
  String $allowed_hosts    = lookup('tct::allowed_hosts', String, 'first'),
  String $backend          = lookup('tct::backend', String, 'first'),
  String $backend_repo     = lookup('tct::backend_repo', String, 'first'),
  String $backend_revision = lookup('tct::backend_revision', String, 'first'),
  String $basname          = lookup('tct::basename', String, 'first'),
  String $baseurl          = lookup('tct::baseurl', String, 'first'),
  String $db_host          = lookup('tct::db_host', String, 'first'),
  String $db_password      = lookup('tct::db_password', String, 'first'),
  String $db_user          = lookup('tct::db_user', String, 'first'),
  String $frontend         = lookup('tct::frontend', String, 'first'),
  String $frontend_repo    = lookup('tct::frontend_repo', String, 'first'),
  String $frontend_revision = lookup('tct::backend_revision', String, 'first'),
  String $install_dir      = lookup('tct::install_dir', String, 'first'),
  String $media_root       = lookup('tct::media_root', String, 'first'),
  String $user             = lookup('tct::user', String, 'first'),
  String $secret_key       = lookup('tct::secret_key', String, 'first'),
  String $www_dir          = lookup('tct::www_dir', String, 'first'),
  String $static_root      = lookup('tct::static_root', String, 'first'),
  String $tct_db           = lookup('tct::tct_db', String, 'first'),
  String $venv_dir             = lookup('tct::venv_dir', String, 'first'),
  String $epubs_src_folder = lookup('tct::epubs_src_folder', String, 'first'),
 ){

  # Add third party package repos
  include ius

  # Add the user
  user { $user :
    ensure     => present,
    name       => $user,
    comment    => "Topic Curation Toolkit",
    home       => $install_dir,
    managehome => false,
  }

  file { $install_dir:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0755',
  }

  # Install the repos
  alert('Install backend repo')
  vcsrepo { "${install_dir}/${backend}":
    ensure   => present,
    provider => git,
    source   => $backend_repo,
    revision => $backend_revision,
  }
  vcsrepo { "${install_dir}/${frontend}":
    ensure   => present,
    provider => git,
    source   => $frontend_repo,
    revision => $frontend_revision,
  }

  # Install python3.5 from the RH community editions
  class { 'python':
    version                     => 'rh-python35-python',
    pip                         => 'present',
    dev                         => 'latest',
    virtualenv                  => 'present',
    gunicorn                    => 'absent',
    use_epel                    => true,
    rhscl_use_public_repository => true,
  }->
  file { 'rh-python35.sh' :
    ensure  => file,
    path    => '/etc/profile.d/rh-python35.sh',
    content => template('tct/rh-python35.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }->
  python::pip { 'pip':
    ensure     => latest,
    pkgname    => 'pip',
    virtualenv => 'system',
    owner      => 'root',
    timeout    => 1800,
  }->
  python::pip { 'virtualenv':
    ensure     => latest,
    pkgname     => 'virtualenv',
    virtualenv => 'system',
    owner      => 'root',
    timeout    => 1800,
  }->
  python::pip { 'setuptools':
    ensure     => latest,
    pkgname    => 'setuptools',
    virtualenv => 'system',
    owner      => 'root',
    timeout    => 1800,
  }->
  #python::pip { 'psycopg2':
  #  #ensure      => '2.7.4',
  #  ensure       => latest,
  #  pkgname      => 'psycopg2',
  #  install_args => '--no-binary :all:',
  #  #virtualenv  => $venv_dir,
  #  virtualenv   => 'system',
  #  owner        => 'root',
  #  timeout      => 1800,
  #  environment  => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-python35/root/usr/lib64/',
  #  #require     => Class['postgresql::server'],
  #}

  file { "${install_dir}/etc" :
    ensure => 'directory',
  }
  file { "requirements.txt" :
    #path   => "/home/${user}/src/requirements.txt",
    ensure  => present,
    #path    => "${venv_dir}/requirements.txt",
    path    => "${install_dir}/etc/requirements.txt",
    owner   => 'root',
    group   => 'root',
    mode    => "0644",
    source  => "puppet:///modules/tct/requirements.txt",
    #require => File[ "$venv_dir" ],
    require => Class[ "python" ],
  }
  python::pyvenv { $venv_dir :
    ensure      => present,
    version     => '3.5',
    systempkgs  => true,
    venv_dir    => $venv_dir,
    owner       => 'root',
    group       => 'root',
    path        => '/opt/rh/rh-python35/root/bin/:/bin:/usr/bin:/usr/local/bin',
    environment => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-python35/root/usr/lib64/',
    require     => [ Class['python'], File['requirements.txt'] ],
    notify      => File[ "${venv_dir}/bin/pip" ],
  }
  file { "${venv_dir}/bin/pip" :
    ensure => link,
    target => '/opt/rh/rh-python35/root/bin/pip',
  }
  python::pip { 'uWSGI':
    ensure     => latest,
    pkgname    => 'uWSGI',
    virtualenv => $venv_dir,
    owner      => 'root',
    timeout    =>  1800,
    environment => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-python35/root/usr/lib64/',
  }
  #python::requirements { "${venv_dir}/requirements.txt":
  python::requirements { "${install_dir}/etc/requirements.txt":
    virtualenv                        => $venv_dir,
    owner                             => 'root',
    group                             => 'root',
    environment                       => 'LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rh/rh-python35/root/usr/lib64/',
    #require                           => [ File['requirements.txt'], Python::Pyvenv["${venv_dir}"], ],
    require                           => File['requirements.txt'],
 }

 # Documentation
  #file { 'requirements-documentation.txt':
  #  ensure                            => present,
  #  path                              => "${venv_dir}/requirements-documentaiton.txt",
  #  owner                             => 'root',
  #  group                             => 'root',
  #  mode                              => '0644',
  #  source                            => "puppet:///modules/tct/requirements-documentation.txt",
  #}
  #python::requirements { "${venv_dir}/requirements-documentation.txt":
  #  virtualenv                        => $venv_dir,
  #  owner                             => 'root',
  #  group                             => 'root',
  #  require                           => Python::Virtualenv["${venv_dir}"],
  #}

  # Testing
  #file { "requirements-testing.txt" :
  #  ensure                            => present,
  #  path                              => "${venv_dir}/requirements-testing.txt",
  #  owner                             => 'root',
  #  group                             => 'root',
  #  mode                              => '0644',
  #  source                            => "puppet:///modules/tct/requirements-testing.txt",
  #}
  

  #package { 'pysch' :
  #  ensure   => '3.0.2',
  #  provider => 'gem',
  #  require => Package['rubygems'],
  #}


}
