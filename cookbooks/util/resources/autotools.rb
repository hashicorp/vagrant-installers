actions :compile, :install, :test

attribute :file, :kind_of => String, :required => true
attribute :config_file, :kind_of => String, :default => "configure"
attribute :config_flags, :kind_of => Array, :default => []
attribute :directory, :kind_of => String
attribute :environment, :kind_of => Hash, :default => {}
attribute :patches, :kind_of => Hash, :default => {}
attribute :target_directory, :kind_of => String, :default => nil

def initialize(*args)
  super

  @action = [:compile, :install]
end
