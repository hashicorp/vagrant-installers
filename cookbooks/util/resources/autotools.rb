actions :compile, :install, :test

attribute :file, :kind_of => String, :required => true
attribute :directory, :kind_of => String
attribute :config_flags, :kind_of => Array, :default => []
attribute :environment, :kind_of => Hash, :default => {}
attribute :config_file, :kind_of => String, :default => "configure"
attribute :patches, :kind_of => Hash, :default => {}

def initialize(*args)
  super

  @action = [:compile, :install]
end
