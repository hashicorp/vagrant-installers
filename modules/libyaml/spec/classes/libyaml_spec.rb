require "spec_helper"

describe "libyaml" do
  let(:facts) { { :test => true } }

  it do
    should contain_autotools("libyaml").with_environment({})
  end
end
