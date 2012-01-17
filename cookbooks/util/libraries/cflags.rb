# Returns a hash of the proper CFLAGS/LDFLAGS for compiling
def cflags
  flags = {
    "LDFLAGS" => "-R#{embedded_dir}/lib -L#{embedded_dir}/lib -I#{embedded_dir}/include",
    "CLFAGS"  => "-I#{embedded_dir}/include -L#{embedded_dir}/lib"
  }

  if platform?("windows")
    # Paths must be Windows-ified
    flags.each do |key, value|
      flags[key] = value.gsub("/", "\\")
    end
  end

  return flags
end
