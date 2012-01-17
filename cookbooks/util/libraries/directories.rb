# Returns the directory that is staged for include in
# the installer.
def staging_dir
  node[:installer][:staging_dir]
end

# Returns the path to the directory that contains
# all of the embedded software.
def embedded_dir
  File.join(node[:installer][:staging_dir], "embedded")
end
