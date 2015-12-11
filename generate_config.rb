#!/usr/bin/env ruby
require 'optparse'

def random_string
  o = [('a'..'z'), ('A'..'Z'), (1..9)].map { |i| i.to_a }.flatten
  (0...12).map { o[rand(o.length)] }.join
end

server = ''
appname = ''
domain = ''
ssh = ''

deploy_user_pass = random_string
user_database_pass = random_string
main_database_pass = random_string

OptionParser.new do |opt|
  opt.on('--server server') { |o| server = o }
  opt.on('--appname appname') { |o| appname = o }
  opt.on('--domain domain') { |o| domain = o }
  opt.on('--ssh ssh') { |o| ssh = o }
end.parse!

path = File.join File.expand_path('../nodes/', __FILE__), "#{server}.json"

raise 'put server, appname and domain. EXAMPLE: ./generate_config.rb --server 1.1.1.1 --appname my_app --domain my-domain.com' if server.empty? || appname.empty? || domain.empty?

data =%{{
  "run_list": [
    "recipe[zsh]",
    "recipe[rvm::system]",
    "recipe[rvm::user]",
    "recipe[nginx]",
    "recipe[postgresql::server]",
    "recipe[database::postgresql]",
    "recipe[unicorn]",
    "recipe[rails]"
  ],
  "users": ["deploy"],
  "rvm":{
    "default_ruby":"ruby-2.2.1",
    "rubies": ["2.2.1"],
    "install_rubies": true,
    "user_installs": [
      {
        "user": "deploy",
        "default_ruby": "ruby-2.2.1"
      }
    ]
  },
  "postgresql":{
    "password":{
      "postgres": "#{main_database_pass}"
    }
  },
  "unicorn": {
    "options": { "backlog": "64" },
    "preload_app": true,
    "worker_processes": "2",
    "worker_timeout": "30",
    "after_fork": "defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection",
    "before_fork": "defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!",
    "config_file": "/home/apps/#{appname}/shared/unicorn.rb",
    "listen": ["/home/apps/#{appname}/shared/tmp/sockets/unicorn.urchi.sock"],
    "pid": "/home/apps/#{appname}/shared/tmp/pids/unicorn.pid",
    "stderr_path": "/home/apps/#{appname}/shared/log/unicorn.log",
    "stdout_path": "/home/apps/#{appname}/shared/log/unicorn.log",
    "working_directory": "/home/apps/#{appname}/current"
  },
  "sites":[
    {
      "deploy_user":{
        "name": "deploy",
        "passwd":"#{deploy_user_pass}",
        "ssh": "#{ssh}",
        "home_path": "/home/apps/#{appname}"
      },
      "app_name": "#{appname}",
      "hostname": ["#{domain}","www.#{domain}"],
      "databases":[
        {
          "username":"#{appname}_user",
          "password":"#{user_database_pass}",
          "host": "127.0.0.1",
          "database":"#{appname}_production",
          "pool_size":"25",
          "env": "production",
          "adapter": "postgresql"
        }
      ]
    }
  ]
}
}
File.open(path, 'w') { |file| file.write(data) }
puts " #{path}\n [Done]"
