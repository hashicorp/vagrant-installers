package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"syscall"

	"github.com/mitchellh/osext"
)

func main() {
	path, err := osext.ExecutableFolder()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load Vagrant: %s\n", err)
		os.Exit(1)
	}

	// Determine some basic directories that we use throughout
	installerDir := filepath.Dir(filepath.Clean(path))
	embeddedDir := filepath.Join(installerDir, "embedded")

	// Find the Vagrant gem
	gemPaths, err := filepath.Glob(
		filepath.Join(embeddedDir, "gems", "gems", "vagrant-*"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to find Vagrant: %s\n", err)
		os.Exit(1)
	}
	for i, v := range gemPaths {
		fullPath := filepath.Join(v, "lib", "vagrant", "pre-rubygems.rb")
		if _, err := os.Stat(fullPath); err != nil {
			gemPaths = gemPaths[0:i-1]
		}
	}
	if len(gemPaths) == 0 {
		fmt.Fprintf(os.Stderr, "Failed to find Vagrant!\n")
		os.Exit(1)
	}
	gemPath := gemPaths[len(gemPaths)-1]
	vagrantExecutable := filepath.Join(gemPath, "bin", "vagrant")

	// Setup the CPP/LDFLAGS so that native extensions can be
	// properly compiled into the Vagrant environment.
	cppflags := "-I" + filepath.Join(embeddedDir, "include")
	ldflags := "-L" + filepath.Join(embeddedDir, "lib")
	if original := os.Getenv("CPPFLAGS"); original != "" {
		cppflags = original + " " + cppflags
	}
	if original := os.Getenv("LDFLAGS"); original != "" {
		ldflags = original + " " + ldflags
	}

	// Set the PATH to include the proper paths into our embedded dir
	path = os.Getenv("PATH")
	if runtime.GOOS == "windows" {
		path = fmt.Sprintf(
			"%s;%s;%s;%s",
			filepath.Join(embeddedDir, "bin"),
			filepath.Join(embeddedDir, "gnuwin32", "bin"),
			filepath.Join(embeddedDir, "mingw", "bin"),
			path)
	} else {
		path = fmt.Sprintf("%s:%s",
			filepath.Join(embeddedDir, "bin"), path)
	}

	newEnv := map[string]string{
		// Setup the environment to prefer our embedded dir over
		// anything the user might have setup on his/her system.
		"CPPFLAGS":      cppflags,
		"GEM_HOME":      filepath.Join(embeddedDir, "gems"),
		"GEM_PATH":      filepath.Join(embeddedDir, "gems"),
		"GEMRC":         filepath.Join(embeddedDir, "etc", "gemrc"),
		"LDFLAGS":       ldflags,
		"PATH":          path,
		"SSL_CERT_FILE": filepath.Join(embeddedDir, "cacert.pem"),

		// Environmental variables used by Vagrant itself
		"VAGRANT_EXECUTABLE":             vagrantExecutable,
		"VAGRANT_INSTALLER_ENV":          "1",
		"VAGRANT_INSTALLER_EMBEDDED_DIR": embeddedDir,
		"VAGRANT_INSTALLER_VERSION":      "2",
	}

	// Unset any RUBYOPT, we don't want this bleeding into our runtime
	newEnv["RUBYOPT"] = ""

	// Set all the environmental variables
	for k, v := range newEnv {
		if err := os.Setenv(k, v); err != nil {
			fmt.Fprintf(os.Stderr, "Error setting env var %s: %s\n", k, err)
			os.Exit(1)
		}
	}

	// Determine the path to Ruby and then start the Vagrant process
	rubyPath := filepath.Join(embeddedDir, "bin", "ruby")
	if runtime.GOOS == "windows" {
		rubyPath += ".exe"
	}

	cmd := exec.Command(rubyPath)
	cmd.Args = make([]string, len(os.Args)+1)
	cmd.Args[0] = "ruby"
	cmd.Args[1] = filepath.Join(gemPath, "lib", "vagrant", "pre-rubygems.rb")
	copy(cmd.Args[2:], os.Args[1:])

	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "Exec error: %s\n", err)
		os.Exit(1)
	}

	exitCode := 0
	if err := cmd.Wait(); err != nil {
		if exiterr, ok := err.(*exec.ExitError); ok {
			// The program has exited with an exit code != 0

			// This works on both Unix and Windows. Although package
			// syscall is generally platform dependent, WaitStatus is
			// defined for both Unix and Windows and in both cases has
			// an ExitStatus() method with the same signature.
			if status, ok := exiterr.Sys().(syscall.WaitStatus); ok {
				exitCode = status.ExitStatus()
			}
		}
	}

	os.Exit(exitCode)
}
