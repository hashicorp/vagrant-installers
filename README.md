# Vagrant Installer Generators

This project builds installers for full-stack software builds for
Vagrant. This allows us to distribute Vagrant as a single executable
item which will install Ruby, RubyGems, Vagrant, etc. in an isolated
environment already ready to run.

**Current status:** Highly experimental. This doesn't yet generate
stable installers. Use at your own risk. This will create stable installers
very soon.

## Building an Installer

### Mac

#### Prerequisites

* [Chef](http://opscode.com/chef)
* [Git](http://git-scm.com/)
* [XCode](http://developer.apple.com/xcode/) (for PackageMaker)

#### Build

    sudo rake

The resulting `dmg` will appear in the `dist` directory.
