# rails_chef_config
Chef solo config for Rails app (Unicorn + NGINX + PostgreSQL + RVM)

I've add simple script that generate configuration depend on variables
```
./generate_config.rb --server 1.1.1.1 --appname my_app --domain my-domain.com
```
Basicaly this chef config create a PostgreSQL database, install RVM, configure NGINX, create Unicorn config file
Hope it helps to figure out how it works.
I'm using Chef Solo + Knife + Berkshelf.
Happy provisioning!
