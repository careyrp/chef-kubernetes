#
# Cookbook Name:: kubernetes
# Recipe:: haproxy
#
# Author:: Maxim Filatov <bregor@evilmartians.com>
#

require 'resolv'

apt_repository 'haproxy' do
  uri 'ppa:vbernat/haproxy-1.8'
  distribution node['lsb']['codename']
end

package 'haproxy'

service 'haproxy' do
  action :nothing
end

master_nodes = search(:node, "roles:#{node['kubernetes']['roles']['master']}")

nameservers = Resolv::DNS::Config.new.lazy_initialize.nameserver_port
nameservers = nameservers.unshift([node['kubernetes']['cluster_dns'], 53])
nameservers.uniq!

if !master_nodes.empty? &&
   master_nodes.all? { |n| n.keys.include? 'kubernetes' }

  master_nodes.map! do |master_node|
    {
      name: k8s_hostname(master_node),
      ip: k8s_ip(master_node)
    }
  end
else
  master_nodes = [
    {
      name: k8s_hostname(node),
      ip: k8s_ip(node)
    }
  ]
end

template '/etc/haproxy/haproxy.cfg' do
  source 'haproxy.cfg.erb'
  variables(
    nodes:     master_nodes,
    resolvers: [
      {
        name: node['kubernetes']['cluster_name'],
        nameservers:     nameservers,
        resolve_retries: 3,
        timeout_retry:   '1s'
      }
    ]
  )
  notifies :restart, 'service[haproxy]'
end

firewall_rule 'deis_builder' do
  port 2222
  protocol :tcp
  command :allow
  only_if do
    node['kubernetes']['enable_firewall'] and
      node['kubernetes']['deis']['enabled'] and
      node['kubernetes']['deis']['route_via'] == 'haproxy'
  end
end
