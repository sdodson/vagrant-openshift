#--
# Copyright 2014 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module Vagrant
  module Openshift
    module Action
      class LocalOpenshift3Checkout
        include CommandHelper

        def initialize(app, env, options)
          @app = app
          @env = env
          @options = options
        end

        def call(env)
          if ENV['GOPATH'].nil?
            puts "You don't seem to have the GOPATH environment variable set on your system."
            puts "See: 'go help gopath' for more details about GOPATH."
            go_path = '.'
          else
            go_path = FileUtils.mkdir_p(
              File.join(ENV['GOPATH'], 'src', 'github.com', 'openshift')
            ).first
          end
          Dir.chdir(go_path) do
            commands = "echo 'Waiting for the cloning process to finish'\n"
            repolist = Constants.openshift3_repos
            #unless @options[:osrepo].nil?
              repolist['origin'] = @options[:oserepo]
            #end
            puts repolist.to_s
            repolist.each do |repo, url|
              commands += %{
  ( #{repo_checkout_bash_command(repo, url)} ) &
  PIDS+=$!\" \";
  }
            end

            commands += "[ -n \"$PIDS\" ] && wait $PIDS\n"
            system(commands)
            puts "OpenShift repositories cloned into #{Dir.pwd}"
          end

          @app.call(env)
        end
      end
    end
  end
end
