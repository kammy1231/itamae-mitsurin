

describe file('/root/test/remote_file.sh') do
  it { should exist }
  it { should be_file }
  it { should be_executable }
end
