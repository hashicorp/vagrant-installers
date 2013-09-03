require "spec_helper"

describe "zlib" do
  it do
    should contain_autotools("libz").with_environment({})
  end
end
