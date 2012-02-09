actions :patch

attribute :source, :kind_of => String, :required => true
attribute :p_level, :kind_of => Integer, :default => 0
attribute :cwd, :kind_of => String, :required => true

def initialize(*args)
  super

  @action = :patch
end
