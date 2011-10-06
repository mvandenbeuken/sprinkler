package :postgres, :provides => :database do
  description 'PostgreSQL database'
  requires :postgres_core, :postgres_user, :postgres_database, :postgres_autostart
end

package :postgres_core do
  apt %w( postgresql postgresql-client libpq-dev )
  
  verify do
    has_executable 'psql'
    has_apt 'postgresql'
    has_apt 'postgresql-client'
    has_apt 'libpq-dev'
  end
end
  
package :postgres_user do
  runner %{echo "CREATE ROLE #{DEPLOY_USER} WITH LOGIN ENCRYPTED PASSWORD '#{DEPLOY_POSTGRES_PASSWORD}';" | sudo -u postgres psql}
  
  verify do
    @commands << "echo 'SELECT ROLNAME FROM PG_ROLES' | sudo -u postgres psql | grep #{DEPLOY_USER}"
  end
end

package :postgres_database do
  runner "sudo -u postgres createdb --owner=#{DEPLOY_USER} #{DB_NAME}"
  
  verify do
    @commands << "sudo -u postgres psql -l | grep #{DB_NAME}"
  end  
end

package :postgres_autostart do
  description "PostgreSQL: Autostart on reboot"
  requires :postgres_core
  
  runner '/usr/sbin/update-rc.d postgresql-8.4 defaults'
end

%w[start stop restart reload].each do |command|
  package :"postgres_#{command}" do
    requires :postgres_core

    runner "/etc/init.d/postgresql-8.4 #{command}"
  end
end