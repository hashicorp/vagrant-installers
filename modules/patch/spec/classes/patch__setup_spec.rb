require "spec_helper"

describe "patch::setup" do
  it do
    should_not contain_package("patch")
  end
end
