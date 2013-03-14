hashicorp_modules = [
  'autotools',
  'bsdtar',
  'build_essential',
  'download',
  'fpm',
  'homebrew',
  'libffi',
  'libiconv',
  'libxml2',
  'libxslt',
  'libyaml',
  'openssl',
  'params_lookup',
  'patch',
  'powershell',
  'readline',
  'ruby',
  'rubyencoder',
  'util',
  'vagrant',
  'vagrant_installer',
  'wget',
  'wix',
  'zlib',
]

hashicorp_modules.each do |module_name|
  # The options to pass for our module
  opts = {}

  # If the LOCAL environmental variable is set, then we load the Puppet
  # modules from a local path.
  if ENV["LOCAL"]
    opts[:path] = "../puppet-modules/modules/#{module_name}"
  else
    opts[:git] = "git://github.com/hashicorp/puppet-modules.git"
    opts[:ref] = "c4f3a120d242a7deff607a3c8837e1c2029cbec7"
    opts[:path] = "modules/#{module_name}"
  end

  mod module_name, opts
end
