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

The Vagrant Installer Generators use Vagrant to generate both the
substrate layer and package layer. The boxes used for generating
these layers can be built using the packer templates located in
`packer/vagrant`.

## Building Substrates and Packages

By default, Vagrant will build substrate layers. The result of Vagrant's
provisioning step is controlled by an environment variable:

* `VAGRANT_BUILD_TYPE` - `substrate` or `package`

The substrate layers must be built prior to building packages. To
build substrates:

```
$ VAGRANT_BUILD_TYPE="substrate" vagrant up
```

Once the generation of the substrate layers has completed, the
packages can be generated. This can be done by either first destroying
the running VMs:

```
$ vagrant destroy --force
$ VAGRANT_BUILD_TYPE="package" vagrant up
```

or by simply re-provisioning the running VMs:

```
$ VAGRANT_BUILD_TYPE="package" vagrant provision
```