require "spec_helper"

describe "zlib" do
  let(:environment) { { "a" => "b" } }

  let(:params) {{
    "autotools_environment" => environment
  }}

  it "should merge the environment with the parameters" do
    should contain_autotools("libz").with_environment(environment)
  end
end
