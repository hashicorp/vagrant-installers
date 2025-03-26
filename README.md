# Vagrant Installer Generators

This project is able to build installers for Vagrant. The installers
contain the full-stack of Vagrant dependencies: Ruby, RubyGems, Vagrant,
etc.

**Current status:** Production quality. This project has generated the
installers and packages in use by Vagrant on Linux, Windows, and macOS
since March, 2012.

## How it Works

1. **Substrate Layer** - This contains all the pre-compiled software
  for the various platforms that Vagrant has installers for. These are
  generated whenever dependencies change and are built/distributed by
  HashiCorp. 

2. **Package Layer** - This is a set of scripts that can install a
  specific version of Vagrant into a substrate and package it up for
  the running operating system. 

## Prerequisites

The Vagrant Installer Generators use GitHub workflows to generate 
both the substrate layer and the package layer. Due to requirements
of the building and packaging process, local builds are no longer
supported.

