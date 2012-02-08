include_recipe "fog"

required = [:aws_secret_access_key, :aws_access_key_id, :bucket]
required.each do |key|
  if !node[:upload][key]
    raise "Upload setting required: #{key}"
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
    file = bucket.files.create(
      :key => "packages/#{node[:vagrant][:revision]}/#{::File.basename(node[:package][:output])}",
      :body => ::File.open(node[:package][:output], "r"),
      :public => true
    )

    # Log it out
    Chef::Log.info("Uploaded: #{file.public_url}")
  end
end
