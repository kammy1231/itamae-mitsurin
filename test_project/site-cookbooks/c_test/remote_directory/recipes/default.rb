

remote_directory "remote_dir test" do
  action :create
  path "/root/test/remote_dir"
  source "../templates/remote_dir"
  mode "755"
  owner "root"
  group "root"
end
