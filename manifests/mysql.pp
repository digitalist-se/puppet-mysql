class mysql (
  $module_root = 'puppet:///modules/mysql/',
  $packages = [
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
  $password = 'password',
  $hostname = 'purple0.nod1.se',
  $local_only = true,
  $create_aegir_user = false,
  $aegir_user = '',
  $aegir_password = '',
  $aegir_host = 'purple0.nod1.se',
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

  exec { 'mysql-remove-anonymous':
    onlyif => 'mysqladmin -ubingoberra status',
    path => ['/bin', '/usr/bin'],
    command => "echo \"DROP USER ''@'localhost'; DROP USER ''@'$hostname';\" | mysql -uroot -p${password}",
    require => [Service['mysql'], Exec['mysqladmin password']],
  }

  define conf_file() {
    file { "/etc/mysql/${name}":
      owner => root,
      group => root,
      mode => 0444,
      source => "${module_root}/files/${name}",
    }
  }

  if ! $local_only {
    file { '/etc/mysql/dbnode-my.cnf':
      owner  => root,
      group  => root,
      mode   => '0444',
      source => 'puppet:///modules/mysql/dbnode-my.cnf',
      path   => '/etc/mysql/my.cnf',
      notify => Service['mysql']
    }

    if $create_aegir_user {
      exec { 'mysql-create-aegir-user':
        unless => "echo 'use mysql;select user from user;' | mysql -uroot -ppassword | grep ${aegir_user} > /dev/null",
        path => ['/bin', '/usr/bin'],
        command => "CREATE USER ${aegir_user} IDENTIFIED BY '${aegir_password}'; GRANT ALL PRIVILEGES ON *.* TO '${aegir_user}'@'${aegir_host}' IDENTIFIED BY '${aegir_password}' WITH GRANT OPTION;",
        require => Service['mysql']
      }
    }
  }
}
