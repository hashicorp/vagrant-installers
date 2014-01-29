# Vagrant Installer Generators

This project is able to build installers for Vagrant. The installers
contain the full-stack of Vagrant dependencies: Ruby, RubyGems, Vagrant,
etc.

**Current status:** Production quality. This project has generated the
installers and packages in use by Vagrant on Linux, Windows, and Mac OS X
since March, 2012.

## How it Works

1. **Substrate Layer** - This contains all the pre-compiled software
  for the various platforms that Vagrant has installers for. These are
  generated whenever dependencies change and are built/distributed by
  HashiCorp. You likely won't need to build these yourself.

2. **Package Layer** - This is a set of scripts that can install a
  specific version of Vagrant into a substrate and package it up for
  the running operating system. You'll invoke this layer, most likely.

## Prerequisites

### Linux (Ubuntu, CentOS):

* [fpm](https://github.com/jordansissel/fpm)
* `unzip`
* `wget`

### Mac OS X:

* XCode (not just the command-line tools)
* `unzip`
* `wget`

### Windows

* [WiX](http://wixtoolset.org/)
