#
# Cookbook Name:: kubernetes
# Recipe:: cni_install
#
# Author:: Maxim Filatov <bregor@evilmartians.com>
#

version         = node['kubernetes']['cni']['version']
plugins_version = node['kubernetes']['cni']['plugins_version']

[
  '/etc/kubernetes/addons',
  '/opt/cni/bin',
  '/etc/cni/net.d',
  "/opt/cni/#{version}",
  "/opt/cni/plugins/#{plugins_version}"
].each do |dir|
  directory dir do
    recursive true
  end
end

tar_extract "https://github.com/containernetworking/cni/releases/download/v#{version}/cni-amd64-v#{version}.tgz" do
  target_dir "/opt/cni/#{version}"
  creates "/opt/cni/#{version}/cnitool"
end

%w(cnitool noop).each do |binary|
  link "/opt/cni/bin/#{binary}" do
    to "../#{version}/#{binary}"
  end
end

tar_extract "https://github.com/containernetworking/plugins/releases/download/v#{plugins_version}/cni-plugins-amd64-v#{plugins_version}.tgz" do
  target_dir "/opt/cni/plugins/#{plugins_version}"
  creates "/opt/cni/plugins/#{plugins_version}/portmap"
end

%w(
  flannel
  ptp
  host-local
  portmap
  tuning
  vlan
  sample
  dhcp
  ipvlan
  macvlan
  loopback
  bridge
).each do |plugin|
  link "/opt/cni/bin/#{plugin}" do
    to "../plugins/#{plugins_version}/#{plugin}"
  end
end
