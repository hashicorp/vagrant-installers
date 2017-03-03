class Dmgbuild < Formula
  desc "Command-line tool to create OS X disk images"
  homepage "https://bitbucket.org/al45tair/dmgbuild"
  url "https://pypi.python.org/packages/source/d/dmgbuild/dmgbuild-1.1.0.tar.gz"
  sha256 "44077d7efe155dfc7229a3d21467e59ea3aeeb6e7292757cae6880fa2709709f"
  head "https://bitbucket.org/al45tair/dmgbuild", :using => :hg

  depends_on :python if MacOS.version <= :snow_leopard

  resource "biplist" do
    url "https://pypi.python.org/packages/source/b/biplist/biplist-1.0.1.tar.gz"
    sha256 "41843579a531958bf0df88b471cf8d446723e640c73c469374e4ac313c33b6a8"
  end

  resource "ds_store" do
    url "https://pypi.python.org/packages/source/d/ds_store/ds_store-1.0.1.tar.gz"
    sha256 "caaad61d183dfa10600dba5346e4cff144804c91c97422e40e4b6bf7b8f4228f"
  end

  resource "mac_alias" do
    url "https://pypi.python.org/packages/source/m/mac_alias/mac_alias-1.1.0.tar.gz"
    sha256 "8b6a2666b58bd0e12d4ae71ee23551198d10a8475abe01d709b0bcb5d1f5c97f"
  end

  # These are already installed in Apple's Python distribution.
  # resource "pyobjc-core"
  # resource "pyobjc-framework-Cocoa"
  # resource "pyobjc-framework-Quartz"

  # Although this is specified in dmgbuild's setup.py, it isn't actually used
  # by dmgbuild. However, it *is* used by ds_store.
  resource "six" do
    url "https://pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz"
    sha256 "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a"
  end

  def install
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python2.7/site-packages"
    %w[biplist ds_store mac_alias six].each do |r|
      resource(r).stage do
        system "python", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    ENV.prepend_create_path "PYTHONPATH", libexec/"lib/python2.7/site-packages"
    system "python", *Language::Python.setup_install_args(libexec)

    bin.install Dir[libexec/"bin/*"]
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  # This test currently fails in the sandbox because dmgbuild calls 'hdiutil
  # create -fs HFS+ ...', which causes hdiutil to attempt to write to
  # /dev/rdisk*. Writing to that location is currently disallowed by Homebrew's
  # sandbox (see Homebrew's 'sandbox.rb').
  test do
    dmgpath = testpath/"test.dmg"
    system bin/"dmgbuild", "Test", dmgpath
    system "hdiutil", "verify", dmgpath
  end
end
