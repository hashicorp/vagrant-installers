# Returns a hash of the proper CFLAGS/LDFLAGS for compiling
def cflags
  return {
    "LDFLAGS" => "-R#{node[:isolated][:lib_dir]} -L#{node[:isolated][:lib_dir]} -I#{node[:isolated][:include_dir]}",
    "CLFAGS"  => "-I#{node[:isolated][:include_dir]} -L#{node[:isolated][:lib_dir]}"
  }
end
