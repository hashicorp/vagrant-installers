require "spec_helper"

describe "fpm" do
  context "with defaults" do
    it do
      should contain_package("fpm").with_ensure(:installed)
    end
  end

  context "with version set" do
    let(:params) { { :version => "1.0.0" } }

    it do
      should contain_package("fpm").with_ensure(params[:version])
    end
  end
end
