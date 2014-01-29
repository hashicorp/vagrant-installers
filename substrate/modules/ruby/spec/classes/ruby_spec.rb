require "spec_helper"

describe "ruby" do
  it do
    expect {
      should contain_autotools("ruby")
    }.to raise_error(Puppet::Error)
  end
end
