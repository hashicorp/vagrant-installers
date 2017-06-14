class Dmgbuild < Formula
  desc "Command-line tool to create OS X disk images"
  homepage "https://bitbucket.org/al45tair/dmgbuild"
  url "https://pypi.python.org/packages/ea/86/e07bd2c8d3eadf101c7ba120409e2c7076b4f7c2ac6a4b99128cb80ffbfd/dmgbuild-1.2.1.tar.gz"
  sha256 "569f83f666650cce416f3c38c56808826659f43be1694dce62531166f2285b54"
  head "https://bitbucket.org/al45tair/dmgbuild", :using => :hg

  depends_on :python if MacOS.version <= :snow_leopard

  resource "biplist" do
    url "https://pypi.python.org/packages/source/b/biplist/biplist-1.0.1.tar.gz"
    sha256 "41843579a531958bf0df88b471cf8d446723e640c73c469374e4ac313c33b6a8"
  end

  resource "ds_store" do
    url "https://pypi.python.org/packages/6f/0a/be913e42817d78277d18efcda1489834eb9294b0274c756c3e8d127faa3e/ds_store-1.1.0.tar.gz"
    sha256 "2381e7cec7dd4c0b7f59165377ab3f9ae039f4b12b6ed2f20f80bbf6e4b17e0f"
  end

  resource "mac_alias" do
    url "https://pypi.python.org/packages/ed/ac/44edb3df422339693cf48348b29ffcb8fc15c63fb13cefba5584b40a2d7a/mac_alias-2.0.0.tar.gz"
    sha256 "96920d721c64859d53a1ae88616384125078c6b729e66e45e5d93709f7db286c"
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
