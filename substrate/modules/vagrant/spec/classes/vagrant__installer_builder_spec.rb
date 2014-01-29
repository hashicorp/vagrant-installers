require "spec_helper"

describe "vagrant::installer_builder" do
  let(:facts) do
    {
      :kernel => 'Linux'
    }
  end

  let(:good_params) do
    {
      :file_cache_dir => "/tmp",
      :install_dir => "/tmp",
      :revision => "foo"
    }
  end

  context "with all params" do
    let(:params) { good_params }

    it do
      should contain_download("vagrant-installer-builder")
    end
  end
end
