def action_patch
  patch_file = "#{Chef::Config[:file_cache_path]}/patch"

  # Upload the patch
  cookbook_file patch_file do
    source new_resource.source
  end

  # Patch!
  execute "patch-#{new_resource.name}" do
    command "patch -p#{new_resource.p_level} -i #{patch_file}"
    cwd     new_resource.cwd
  end
end
