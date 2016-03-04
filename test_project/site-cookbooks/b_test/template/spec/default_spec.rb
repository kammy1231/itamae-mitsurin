

describe file('/root/test/template') do
  it { should exist }
  it { should be_file }
  its(:content) { should match %!hello! }
end
