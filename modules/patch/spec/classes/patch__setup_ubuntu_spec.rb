require "spec_helper"

describe "patch::setup" do
  context "on Ubuntu" do
    let(:facts) do
      { :operatingsystem => 'Ubuntu' }
    end

    it do
      should contain_package("patch")
    end
  end
end
