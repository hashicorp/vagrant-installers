require "spec_helper"

describe "libffi" do
  context "on Darwin" do
    let(:facts) do
      {
        :operatingsystem => 'Darwin',
        :test => true
      }
    end

    it "should call autotools with proper environment" do
      environment = {
        "CFLAGS" => "-arch i386 -arch x86_64",
        "LDFLAGS" => "-arch i386 -arch x86_64",
      }

      should contain_autotools("libffi").with_environment(environment)
    end
  end
end
