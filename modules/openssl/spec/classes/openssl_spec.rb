require "spec_helper"

describe "openssl" do
  let(:facts) { { :test => true } }

  it { should include_class("openssl::install::linux") }
end
