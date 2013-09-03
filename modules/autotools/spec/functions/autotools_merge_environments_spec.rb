require "spec_helper"

describe "autotools_merge_environments" do
  it do
    a = { "a" => "foo", "b" => "foo2" }
    b = { "a" => "bar", "c" => "baz" }
    c = { "a" => "foo bar", "b" => "foo2", "c" => "baz" }

    should run.with_params(a, b).and_return(c)
  end

  it "should work with nil arguments" do
    a = { "a" => "foo" }
    b = nil

    should run.with_params(a, b).and_return(a)
  end

  it "should work with empty arguments" do
    a = { "a" => "foo" }
    b = ""

    should run.with_params(a, b).and_return(a)
  end
end
