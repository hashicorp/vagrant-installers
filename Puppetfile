hashicorp_modules = [
  'autotools',
  'build_essential',
  'libffi',
  'libyaml',
  'openssl',
  'params_lookup',
  'patch',
  'readline',
  'ruby',
  'util',
  'vagrant',
  'vagrant_installer',
  'wget',
  'zlib',
]

hashicorp_modules.each do |module_name|
  mod module_name,
    :git => "git://github.com/hashicorp/puppet-modules.git",
    :path => "modules/#{module_name}"
end
