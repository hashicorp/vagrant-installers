required = [:aws_secret_access_key, :aws_access_key_id, :bucket]
required.each do |key|
  if !node[:upload][key]
    raise "Upload setting required: #{key}"
  end
end

#----------------------------------------------------------------------
# Setup Fog
#----------------------------------------------------------------------
gem_package "fog"

ruby_block "reset-gem-for-fog" do
  block do
    Gem.clear_paths
    require 'fog'
  end
end

#----------------------------------------------------------------------
# Upload!
#----------------------------------------------------------------------
ruby_block "upload-package" do
  block do
    # Create a connection
    connection = Fog::Storage.new(
      :provider => "AWS",
      :aws_secret_access_key => node[:upload][:aws_secret_access_key],
      :aws_access_key_id     => node[:upload][:aws_access_key_id]
    )

    # Grab the bucket
    bucket = connection.directories.get(node[:upload][:bucket])

    # Upload the package
    bucket.files.create(
      :key => "packages/#{node[:vagrant][:revision]}/#{::File.basename(node[:package][:output])}",
      :body => ::File.open(node[:package][:output], "r"),
      :public => true
    )
  end
end
