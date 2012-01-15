# Returns a hash of the proper CFLAGS/LDFLAGS for compiling
def cflags
  return {
    "LDFLAGS" => "-R#{node[:installer][:staging_dir]}/lib -L#{node[:installer][:staging_dir]}/lib -I#{node[:installer][:staging_dir]}/include",
    "CLFAGS"  => "-I#{node[:installer][:staging_dir]}/include -L#{node[:installer][:staging_dir]}/lib"
  }
end
