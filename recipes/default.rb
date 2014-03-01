#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2014, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'balanced-apt'
include_recipe 'nginx'

package 'balanced-docs' do
  action :upgrade unless node['balanced-docs']['version']
  version node['balanced-docs']['version']
end

template "#{node['nginx']['dir']}/sites-enabled/balanced-docs.conf" do
  source 'balanced-docs.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :reload, 'service[nginx]'
end
