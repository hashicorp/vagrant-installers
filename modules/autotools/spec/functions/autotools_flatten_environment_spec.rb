require "spec_helper"

describe "autotools_flatten_environment" do
  it do
    a = { "a" => "foo", "b" => "foo2" }
    b = ["a=foo", "b=foo2"]

    should run.with_params(a).and_return(b)
  end

  it do
    should run.with_params().and_raise_error(Puppet::ParseError)
  end

  it do
    should run.with_params(1, 2, 3).and_raise_error(Puppet::ParseError)
  end
end
