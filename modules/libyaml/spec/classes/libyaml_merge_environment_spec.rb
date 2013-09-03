require "spec_helper"

describe "libyaml" do
  let(:environment) { { "a" => "b" } }

  let(:params) {{
    "autotools_environment" => environment
  }}

  it "should merge the environment with the parameters" do
    should contain_autotools("libyaml").with_environment(environment)
  end
end
