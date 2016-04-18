require 'serverspec'
require 'net/ssh'
require 'specinfra/helper/set'
require 'json'
include Specinfra::Helper::Set

set :backend, :ssh

 if ENV['ASK_SUDO_PASSWORD']
   begin
     require 'highline/import'
   rescue LoadError
     fail "highline is not available. Try installing it."
   end
   set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
 else
   set :sudo_password, ENV['SUDO_PASSWORD']
 end

host = ENV['TARGET_HOST']
node_file = ENV['NODE_FILE']
attributes = JSON.parse(File.read(node_file), symbolize_names: true)
set_property attributes

options = Net::SSH::Config.for(host)
options[:user] = ENV['SSH_USER']
options[:password] = ENV['SSH_PASSWORD']
options[:keys] = ENV['SSH_KEY']
options[:port] = ENV['SSH_PORT']

set :host, options[:host_name] || host
set :shell, '/bin/bash'
set :ssh_options, options

set :request_pty, true
