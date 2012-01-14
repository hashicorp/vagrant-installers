# Create the directories which will store our isolated environment
[:dir, :include_dir, :lib_dir].each do |dir_type|
  directory node[:isolated][dir_type] do
    owner "root"
    mode  0755
    recursive true
  end
end
