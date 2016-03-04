

remote_file "remote_file test" do
  path "/root/test/remote_file.sh"
  source "../files/remote_file.sh"
  mode "777"
  owner "root"
  group "root"
end
