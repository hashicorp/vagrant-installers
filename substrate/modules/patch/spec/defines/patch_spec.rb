require "spec_helper"

describe "patch" do
  let(:title) { "file" }

  let(:params) { {
    :content => "foo",
    :prefixlevel => "1",
    :cwd => "/tmp",
  } }

  let(:patch_file) { "/tmp/patch_#{title}" }

  it { should include_class("patch::setup") }

  it do
    should contain_file(patch_file).
      with_content(params[:content])
  end

  it do
    should contain_exec("patch-#{title}").
      with_command("patch -p#{params[:prefixlevel]} -i #{patch_file}").
      with_cwd(params[:cwd])
  end
end
