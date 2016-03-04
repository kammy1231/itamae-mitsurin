

describe file('/root/test/remote_dir') do
  it { should be_directory }
  it { should be_owned_by 'root' }
  it { should be_mode 755 }
end

describe file('/root/test/remote_dir/a.txt') do
  it { should exist }
end

describe file('/root/test/remote_dir/b.txt') do
  it { should exist }
end

describe file('/root/test/remote_dir/c.txt') do
  it { should exist }
  it { should be_mode 755 }
end
