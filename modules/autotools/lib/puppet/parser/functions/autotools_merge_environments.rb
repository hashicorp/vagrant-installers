module Puppet::Parser::Functions
  # This function takes multiple environment hashes and merges them
  # into one by concatenating the strings of matching keys in the order
  # that the arguments appear.
  #
  # The hashes can then be passed into `autotools_flatten_environment`
  # before being passed into `exec`.
  newfunction(:autotools_merge_environments, :type => :rvalue) do |args|
    if args.length < 1
      raise Puppet::ParseError, "autotools_merge_environments() takes at least one argument"
    end

    result = {}

    # Go through each argument in order, then each key and value, and
    # slowly build up the resulting hash.
    args.each do |environment|
      # Ignore nil arguments.
      if environment.is_a?(Hash)
        environment.each do |key, value|
          if !result.has_key?(key)
            result[key] = value
          else
            result[key] += " #{value}"
          end
        end
      end
    end

    result
  end
end
