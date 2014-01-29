module Puppet::Parser::Functions
  # This function takes a hash environment and flattens it into the array
  # that `exec` expects.
  newfunction(:autotools_flatten_environment, :type => :rvalue) do |args|
    if args.length != 1
      raise Puppet::ParseError, "autotools_flatten_environment() takes one argument"
    end

    result = []

    args[0].each do |key, value|
      result << "#{key}=#{value}"
    end

    # We sort the results just so that tests pass across Ruby versions since
    # Hash traversal order is non-deterministic
    result.sort
  end
end
