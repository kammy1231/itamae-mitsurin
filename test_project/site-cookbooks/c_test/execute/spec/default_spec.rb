

describe file('/root/test/execute.txt') do
  it { should exist }
  it { should contain 'execute' }
end
