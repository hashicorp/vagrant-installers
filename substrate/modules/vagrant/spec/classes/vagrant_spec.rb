require "spec_helper"

describe "vagrant" do
  let(:params) { {
    :embedded_dir => "foo",
    :revision => "foo"
  } }

  it { should_not contain_powershell("extract-vagrant") }

  it do
    should contain_exec("vagrant-gem-rename").
      with_command(/ruby\s/)
  end

  it do
    should contain_exec("vagrant-gem-install").
      with_command(/gem\s/)
  end
end
