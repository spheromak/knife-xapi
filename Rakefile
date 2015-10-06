#
# Author:: Jesse Nelson (<spheromak@gmail.com>)
#
# Copyright:: Copyright (c) 2012  Jesse Nelson
# 
# License:: Apache License, Version 2.0
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
$:.unshift(File.dirname(__FILE__) + '/lib')
require 'rake'
require 'jeweler'
require 'knife-xapi/version'

Jeweler::Tasks.new do |gem|
  gem.name = 'knife-xapi'
  gem.version = KnifeXenserver::VERSION
  gem.platform = Gem::Platform::RUBY
  gem.has_rdoc = true
  gem.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  gem.summary = "Xen API Support for Chef's Knife Command"
  gem.description = gem.summary
  gem.author = "Jesse Nelson"
  gem.email = "spheromak@gmail.com"
  gem.homepage = "https://github.com/spheromak/knife-xapi"

  gem.require_path = 'lib'
  gem.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
end
Jeweler::RubygemsDotOrgTasks.new
