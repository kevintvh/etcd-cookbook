# Encoding: UTF-8
# Recipe:: _service
#
#

## handle rhel7/debian
systemd = false
init = false
upstart = true
init_provider = Chef::Provider::Service::Upstart

if node[:platform_family] == 'rhel' && node[:platform_version].to_i >= 7
  systemd = true
  upstart = false
  init_provider = Chef::Provider::Service::Systemd
end
if node[:platform] == "debian"
  init_provider = Chef::Provider::Service::Init::Debian
  init=true
  upstart=false
end

directory File.dirname node[:etcd][:state_dir]

template "/etc/init.d/etcd" do
  mode 0755
  only_if { init }
end

template "/etc/default/etcd" do
  mode 0644
  source "etcd-default.erb" 
  variables(args: Etcd.args)
  notifies :restart, 'service[etcd]' if node[:etcd][:trigger_restart]
  only_if { init }
end

# TODO: use this on other sytemd platforms
template '/etc/systemd/system/etcd.service' do
  mode 0644
  variables(args: Etcd.args)
  notifies :run, 'execute[systemd_reload_units]', :immediate
  notifies :restart, 'service[etcd]' if node[:etcd][:trigger_restart]
  only_if { systemd }
end

template '/etc/init/etcd.conf' do
  mode 0644
  variables(args: Etcd.args)
  notifies :restart, 'service[etcd]' if node[:etcd][:trigger_restart]
  only_if { upstart }
end

# TODO: use this on other sytemd platforms
template '/etc/systemd/system/etcd.service' do
  mode 0644
  variables(args: Etcd.args)
  notifies :run, 'execute[systemd_reload_units]', :immediate
  notifies :restart, 'service[etcd]' if node[:etcd][:trigger_restart]
  only_if { systemd }
end

execute 'systemd_reload_units' do
  action :nothing
  command '/bin/systemctl daemon-reload'
end

service 'etcd' do
  provider init_provider
  supports status: true, restart: true, reload: true
  action [:enable, :start]
end
