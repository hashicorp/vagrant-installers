# Vagrant Installer Generators

This project builds installers for full-stack software builds for
Vagrant. This allows us to distribute Vagrant as a single executable
item which will install Ruby, RubyGems, Vagrant, etc. in an isolated
environment already ready to run.

**Current status:** Production quality. This project has generated the
installers and packages in use by Vagrant on Linux, Windows, and Mac OS X
since March, 2012.

## How it Works (Technically)

The general steps are given below. Note that for specific platforms,
there may be more steps involved but the basic idea is the same:

1. Create a directory to store a fully self-contained Vagrant install.
   On Linux, this is typically `/tmp/vagrant-temp`. Software built into
   this directory is placed in the `embedded` directory.
2. Build Ruby using only libraries in the isolated directory, and install
   into the embedded directory.
3. Build the Vagrant gem from source.
4. Install the Vagrant gem using the isolated Ruby.
5. Create a binary stub that simply proxies to the install Vagrant binary.
   This typically goes in `/tmp/vagrant-temp/bin`. The binary stub is
   responsible for making sure that _only_ the embedded software is used.
6. Build an installer that simply copies the directory structure of the
   isolated directory to some installation location.

## Building an Installer

### Mac

#### Prerequisites

* Command Line Tools for Mac OS X
* [Homebrew](http://mxcl.github.com/homebrew/)
* [Puppet](http://puppetlabs.com/misc/download-options/)
* RubyGems
* [Developer ID Setup with Keychain](https://developer.apple.com/library/mac/#documentation/ToolsLanguages/Conceptual/OSXWorkflowGuide/CodeSigning/CodeSigning.html#//apple_ref/doc/uid/TP40011201-CH7-SW1/)

#### Build

Edit the `hiera/Darwin.yaml` file and change the parameters to your signing key & user:

    darwin_pkg_sign: "Developer ID Installer: John Doe"
    homebrew_user: jdoe

    ./run.sh ${REVISION} ${OUTPUT_DIRECTORY}

The resulting `dmg` will appear in the output directory.

### Windows

In an administrator PowerShell console:

    > Set-ExecutionPolicy Bypass
    > .\run.ps1
