class mysql (
  $module_root = '/tmp/vagrant-puppet/manifests/modules/mysql',
  $packages = [
    'mysql-client',
    'mysql-common',
    'mysql-server'
  ],
  $conf_files = [
    'conf.d/char.cnf',
    'conf.d/default.cnf',
    'conf.d/innodb.cnf',
    'conf.d/old_passwords.cnf',
    'conf.d/slow-query.cnf',
    'my.cnf'
  ],
  $password = 'password'
) {
  package { $packages:
    ensure => installed,
  }

  service { mysql:
    enable    => true,
    ensure    => running,
    subscribe => Package['mysql-server'],
  }

  # We need to adjust the configuration files to Lucid.
  #conf_file { $conf_files:
  #  require => Package['mysql-server'],
  #}

  exec { 'mysqladmin password':
    unless => "mysqladmin -uroot -p${password} status",
    path => ['/bin', '/usr/bin'],
    command => "mysqladmin -uroot password ${password}",
    require => Service['mysql'],
  }

  define conf_file() {
    file { "/etc/mysql/${name}":
      owner => root,
      group => root,
      mode => 0444,
      source => "${module_root}/files/${name}",
    }
  }
}
