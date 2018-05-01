#
# Copyright:: Copyright (c) 2013-2014 Chef Software, Inc.
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

name "python"

if ohai["platform"] != "windows"
  default_version "2.7.14"

  dependency "ncurses"
  dependency "zlib"
  dependency "openssl"
  dependency "bzip2"
  dependency "libsqlite3"

  source :url => "http://python.org/ftp/python/#{version}/Python-#{version}.tgz",
         :sha256 => "304c9b202ea6fbd0a4a8e0ad3733715fbd4749f2204a9173a58ec53c32ea73e8"

  relative_path "Python-#{version}"

  env = {
    "CFLAGS" => "-I#{install_dir}/embedded/include -O2 -g -pipe",
    "LDFLAGS" => "-Wl,-rpath,#{install_dir}/embedded/lib -L#{install_dir}/embedded/lib",
  }

  python_configure = ["./configure",
                      "--enable-universalsdk=/",
                      "--prefix=#{install_dir}/embedded"]

  if ohai["platform_family"] == "mac_os_x"
    python_configure.push("--enable-ipv6",
                          "--with-universal-archs=intel",
                          "--enable-shared")
  end

  python_configure.push("--with-dbmliborder=")

  build do
    ship_license "PSFL"
    patch :source => "python-2.7.11-avoid-allocating-thunks-in-ctypes.patch" if linux?
    patch :source => "python-2.7.11-fix-platform-ubuntu.diff" if linux?

    command python_configure.join(" "), :env => env
    command "make -j #{workers}", :env => env
    command "make install", :env => env
    delete "#{install_dir}/embedded/lib/python2.7/test"

    # There exists no configure flag to tell Python to not compile readline support :(
    block do
      FileUtils.rm_f(Dir.glob("#{install_dir}/embedded/lib/python2.7/lib-dynload/readline.*"))
    end
  end

else
  default_version "2.7.14"

  dependency "vc_redist"
  dependency "vc_python"

  zipfile = "python2.7.14.7z"
  source :url => "https://github.com/derekwbrown/derekwbrown.github.io/blob/master/python2.7.14.7z",
         :sha256 => "5d3defc39071c8be9cfc7996c58b797ee6758b4e931ed7e353a2c19aaa1f804d"

  build do
    # In case Python is already installed on the build machine well... let's uninstall it
    # (fortunately we're building in a VM :) )
    mkdir "#{windows_safe_path(install_dir)}\\embedded"
    command "7z x -o #{windows_safe_path(install_dir)}\\embedded #{zipfile}

    command "SETX PYTHONPATH \"#{windows_safe_path(install_dir)}\\embedded\""
  end
end
