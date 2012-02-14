#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: wix
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
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

download_path = ::File.join(Chef::Config[:file_cache_path], "wix.zip")

cookbook_file download_path do
  source "wix.zip"
end

windows_zipfile "wix" do
  path node[:wix][:home]
  source download_path
  not_if do
    ::File.exists?(::File.join(node[:wix][:home], "heat.exe"))
  end
end

windows_path node[:wix][:home] do
  action :add
end
