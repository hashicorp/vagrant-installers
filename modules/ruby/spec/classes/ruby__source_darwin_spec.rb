require "spec_helper"

describe "ruby::source" do
  context "on Darwin" do
    let(:facts) do
      {
        :operatingsystem => 'Darwin',
        :test => true
      }
    end

    it do
      should contain_autotools("ruby").
        with_configure_flags(/ --with-arch=x86_64,i386/)
    end
  end
end
