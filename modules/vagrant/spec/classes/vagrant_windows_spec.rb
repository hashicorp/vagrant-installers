require "spec_helper"

describe "vagrant" do
  let(:params) { {
    :embedded_dir => "foo",
    :revision => "foo"
  } }

  context "on Windows" do
    let(:facts) do
      { :operatingsystem => 'windows' }
    end

    it { should contain_powershell("extract-vagrant") }

    it do
      should contain_exec("vagrant-gem-rename").
        with_command(/ruby\.exe/)
    end

    it do
      should contain_exec("vagrant-gem-install").
        with_command(/gem\.bat/)
    end
  end
end
