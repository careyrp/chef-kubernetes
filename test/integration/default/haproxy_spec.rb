describe package('haproxy') do
  it { should be_installed }
  its('version') { should cmp >= '1.8' }
end

describe systemd_service('haproxy') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
