# Just a convenient var since this value is used quite a bit
lib_version = "1.0.0"

#----------------------------------------------------------------------
# Compilation
#----------------------------------------------------------------------
# Compile the libraries for both 32 and 64 bit
[["32", "darwin-i386-cc"], ["64", "darwin64-x86_64-cc"]].each do |bits, target|
  # Set a new target directory for this compilation so that we separate
  # both the 32 and 64-bit.
  target_directory = "#{Chef::Config[:file_cache_path]}/openssl-#{bits}"

  # Actions for the compilation. We "install" the 32 bit one just to install
  # one, but we move into place universal binary versions later.
  actions = [:compile]
  actions << :install if bits == "64"

  # Compile OpenSSL for the correct target
  util_autotools "openssl-#{bits}" do
    file             "openssl-1.0.0g.tar.gz"
    config_file      "Configure"
    config_flags     [target, "shared"]
    target_directory target_directory
    action           actions
  end
end

#----------------------------------------------------------------------
# Create a Universal Binary
#
# OpenSSL has no built-in support for creating a universal binary
# so we actually take both the 32-bit and 64-bit versions and then
# lipo them together to get our final result
#----------------------------------------------------------------------
final_directory = ::File.join(Chef::Config[:file_cache_path], "openssl-final")

# Create the directory to store our final libraries
directory final_directory do
  mode 0755
end

# Perform the surgery on the libraries to stitch them together
["libssl", "libcrypto"].each do |lib|
  lib_filename     = "#{lib}.#{lib_version}.dylib"
  lib32_dylib_path = "openssl-32/#{lib_filename}"
  lib64_dylib_path = "openssl-64/#{lib_filename}"
  lib32_static_path = "openssl-32/#{lib}.a"
  lib64_static_path = "openssl-64/#{lib}.a"
  target_dylib     = "#{final_directory}/#{lib_filename}"
  target_static    = "#{final_directory}/#{lib}.a"

  # Lipo the libraries together to form a universal binary
  execute "lipo-#{lib}" do
    command "lipo -create #{lib32_dylib_path} #{lib64_dylib_path} -output #{target_dylib}"
    cwd     Chef::Config[:file_cache_path]
  end

  execute "lipo-#{lib}-static" do
    command "lipo -create #{lib32_static_path} #{lib64_static_path} -output #{target_static}"
    cwd     Chef::Config[:file_cache_path]
  end

  execute "ranlib-#{lib}-static" do
    command "ranlib #{target_static}"
    cwd     Chef::Config[:file_cache_path]
  end

  # Setup the ID and rpaths properly on the compiled binary
  execute "#{lib}-id" do
    command "install_name_tool -id @rpath/#{lib_filename} #{target_dylib}"
    cwd     Chef::Config[:file_cache_path]
  end

  if lib == "libssl"
    old_rpath = "#{embedded_dir}/lib/libcrypto.#{lib_version}.dylib"
    new_rpath = "@rpath/libcrypto.#{lib_version}.dylib"

    # We also need to change the rpath to the libcrypto lib...
    execute "#{lib}-rpath" do
      command "install_name_tool -change #{old_rpath} #{new_rpath} #{target_dylib}"
      cwd     Chef::Config[:file_cache_path]
    end
  end

  # "Install" the library by moving it into the final embedded dir
  execute "#{lib}-move-universal" do
    command "cp #{target_dylib} #{embedded_dir}/lib/#{lib_filename}"
    cwd     Chef::Config[:file_cache_path]
  end

  execute "#{lib}-move-static" do
    command "cp #{target_static} #{embedded_dir}/lib/#{lib}.a"
    cwd     Chef::Config[:file_cache_path]
  end
end
