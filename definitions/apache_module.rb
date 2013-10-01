#
# Cookbook Name:: apache2
# Definition:: apache_module
#
# Copyright 2008-2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#



define :apache_module, :enable => true, :conf => false do
  include_recipe "apache2"
  extend ::Apache::Helpers

  params[:filename] = params[:filename] || "mod_#{params[:name]}.so"
  params[:module_path] = params[:module_path] || "#{node['apache']['libexecdir']}/#{params[:filename]}"

  if params[:conf]
    apache_conf params[:name]
  end

  if platform_family?("rhel", "fedora", "arch", "suse", "freebsd", "windows")
    file "#{node['apache']['dir']}/mods-available/#{params[:name]}.load" do
      content "LoadModule #{params[:name]}_module #{params[:module_path]}\n"
      mode 0644
    end
  end

  if params[:enable]
    cmd = generate_bash_command_line("#{node['apache']['bin_dir']}/a2enmod #{params[:name]}")
    execute "a2enmod #{params[:name]}" do
      command cmd
      notifies :restart, "service[apache2]"
      not_if do (::File.symlink?("#{node['apache']['dir']}/mods-enabled/#{params[:name]}.load") and
        ((::File.exists?("#{node['apache']['dir']}/mods-available/#{params[:name]}.conf"))?
          (::File.symlink?("#{node['apache']['dir']}/mods-enabled/#{params[:name]}.conf")):(true)))
      end
    end
  else
    cmd = generate_bash_command_line("#{node['apache']['bin_dir']}/a2dismod #{params[:name]}")
    execute "a2dismod #{params[:name]}" do
      command cmd
      notifies :restart, "service[apache2]"
      only_if do ::File.symlink?("#{node['apache']['dir']}/mods-enabled/#{params[:name]}.load") end
    end
  end
end
