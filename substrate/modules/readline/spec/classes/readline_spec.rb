require "spec_helper"

describe "readline" do
  it do
    should contain_autotools("readline").with_environment({})
  end

  it do
    should_not contain_patch("patch-readline")
  end
end
