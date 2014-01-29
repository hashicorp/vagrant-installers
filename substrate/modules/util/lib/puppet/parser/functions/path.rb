module Puppet::Parser::Functions
  # This function takes a path and converts the file separators to the right
  # thing based on the operating system, from a Unix path.
  newfunction(:path, :type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, "path() takes one argument"
    end

    os = lookupvar('operatingsystem')
    next args[0] if os != 'windows'
    args[0].gsub("/", "\\")
  end
end
