

describe file('/root/linktest') do
  it { should be_symlink }
end
