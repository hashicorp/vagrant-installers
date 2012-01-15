# Vagrant Installer Generators

This project builds installers for full-stack software builds for
Vagrant. This allows us to distribute Vagrant as a single executable
item which will install Ruby, RubyGems, Vagrant, etc. in an isolated
environment already ready to run.

**Current status:** Highly experimental. This doesn't yet generate
stable installers. Use at your own risk. This will create stable installers
very soon.

## How it works

First, you must be on the **target system** you'd like to create an
installer for. For example, to build a Mac OS X installer, you must
have a Mac OS X computer to run the generator.

Next, install Ruby, Chef, and Rake. Finally, run:

    rake

The resulting installer will appear in the `dist` directory.
