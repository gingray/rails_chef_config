#
# Cookbook Name:: urchi
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#
include_recipe "database::postgresql"

postgresql_connection_info = {:host => "127.0.0.1",
                              :port => 5432,
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}
node["sites"].each do |site|

  mkdir = proc do |path|
    directory path do
      owner site["deploy_user"]["name"]
      group "deploy"
      mode "0775"
      recursive true
    end
  end

  mkdir.call site["deploy_user"]["home_path"]

  site["databases"].each do |database|
    postgresql_database_user database["username"] do
      connection postgresql_connection_info
      password database["password"]

      action :create
    end

    postgresql_database database["database"] do
      connection postgresql_connection_info
      connection_limit '-1'
      owner database["user"]
      action :create
    end
  end

  unicorn_config node["unicorn"]["config_file"] do
    node["unicorn"].each do |key, value|
      send(key.to_sym, value)
    end
  end

  app_name = site["app_name"]
  hostname = site["hostname"].join " "
  root_path = "/home/apps/#{app_name}/current/public"
  app_shared = "/home/apps/#{app_name}/shared"
  log_dir = "#{app_shared}/log"

  config_shared = "#{app_shared}/config"

  mkdir.call app_shared
  mkdir.call log_dir
  mkdir.call config_shared

  template "#{config_shared}/database.yml" do
    source 'rails_database.erb'
    variables environments: site["databases"]
  end

  template "#{config_shared}/secrets.yml" do
    source 'rails_secrets.erb'
  end


  template "/etc/init.d/unicorn_#{app_name}" do
    source 'unicorn_init.erb'
    variables working_directory: node["unicorn"]["working_directory"], config_file: node["unicorn"]["config_file"], env: "production"
    mode "0755"
  end

  app_listen = node["unicorn"]["listen"].first
  template "/etc/nginx/sites-available/#{app_name}" do
    source 'nginx_conf.erb'
    variables app_name: app_name, hostname: hostname, root_path: root_path, app_listen: app_listen, log_dir: log_dir
    notifies :reload, resources(service: 'nginx')
  end


  link "/etc/nginx/sites-enabled/#{app_name}" do
    to "/etc/nginx/sites-available/#{app_name}"
  end
end
