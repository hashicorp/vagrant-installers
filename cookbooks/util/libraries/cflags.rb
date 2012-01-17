# Returns a hash of the proper CFLAGS/LDFLAGS for compiling
def cflags
  flags = {
    "LDFLAGS" => "-R#{node[:installer][:staging_dir]}/lib -L#{node[:installer][:staging_dir]}/lib -I#{node[:installer][:staging_dir]}/include",
    "CLFAGS"  => "-I#{node[:installer][:staging_dir]}/include -L#{node[:installer][:staging_dir]}/lib"
  }

  if platform?("windows")
    # Paths must be Windows-ified
    flags.each do |key, value|
      flags[key] = value.gsub("/", "\\")
    end
  end

  return flags
end
