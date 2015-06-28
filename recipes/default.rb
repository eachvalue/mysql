#
# Cookbook Name:: mysql
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
%w{mysql mysql-server}.each do |pkg|
  package pkg do
    action :install
  end
end

service "mysqld" do
  action [ :enable, :start ]
end

bash "mysql_secure_installation" do
  code <<-EOH
  /usr/bin/mysqladmin drop test -f
  /usr/bin/mysql -e "delete from user where user = '';" -D mysql
  /usr/bin/mysql -e "delete from user where user = 'root' and host = \'#{node[:fqdn]}\';" -D mysql
  /usr/bin/mysql -e "SET PASSWORD FOR 'root'@'::1' = PASSWORD('#{node[:mysql][:db_root_password]}');" -D mysql
  /usr/bin/mysql -e "SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('#{node[:mysql][:db_root_password]}');" -D mysql
  /usr/bin/mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('#{node[:mysql][:db_root_password]}');" -D mysql
  /usr/bin/mysqladmin flush-privileges -p#{node[:mysql][:db_root_password]}
  EOH
  only_if "/usr/bin/mysql -u root -e 'show databases;'"
end

execute "create database" do
  command "mysql -u root -p#{node[:mysql][:db_root_password]} -e 'CREATE DATABASE #{node[:mysql][:db_name]} DEFAULT CHARACTER SET utf8;'"
  not_if "mysql -u root -p#{node[:mysql][:db_root_password]} -e 'USE #{node[:mysql][:db_name]};'"
end

execute "create user #{node[:mysql][:db_user]}" do
  command "mysql -u root -p#{node[:mysql][:db_root_password]} -e \"GRANT ALL PRIVILEGES ON #{node[:mysql][:db_name]}.* TO #{node[:mysql][:db_user]}@localhost IDENTIFIED BY '#{node[:mysql][:db_password]}';\""
  not_if "mysql -u #{node[:mysql][:db_user]} -p#{node[:mysql][:db_password]} -e 'USE #{node[:mysql][:db_name]};'"
end

template "/etc/my.cnf" do
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[mysqld]"
end
