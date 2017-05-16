package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"syscall"

	"github.com/mitchellh/osext"
)

const envPrefix = "VAGRANT_OLD_ENV"

func main() {
	debug := os.Getenv("VAGRANT_DEBUG_LAUNCHER") != ""

	// Get the path to the executable. This path doesn't resolve symlinks
	// so we have to do that afterwards to find the real binary.
	path, err := osext.Executable()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load Vagrant: %s\n", err)
		os.Exit(1)
	}
	if debug {
		log.Printf("launcher: path = %s", path)
	}
	for {
		fi, err := os.Lstat(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to stat executable: %s\n", err)
			os.Exit(1)
		}
		if fi.Mode()&os.ModeSymlink == 0 {
			break
		}

		// The executable is a symlink, so resolve it
		path, err = os.Readlink(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Failed to load Vagrant: %s\n", err)
			os.Exit(1)
		}
		if debug {
			log.Printf("launcher: resolved symlink = %s", path)
		}
	}

	// Determine some basic directories that we use throughout
	path = filepath.Dir(filepath.Clean(path))
	installerDir := filepath.Dir(path)
	embeddedDir := filepath.Join(installerDir, "embedded")
	if debug {
		log.Printf("launcher: installerDir = %s", installerDir)
		log.Printf("launcher: embeddedDir = %s", embeddedDir)
	}

	// Find the Vagrant gem
	gemPaths, err := filepath.Glob(
		filepath.Join(embeddedDir, "gems", "gems", "vagrant-*"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to find Vagrant: %s\n", err)
		os.Exit(1)
	}
	if debug {
		log.Printf("launcher: gemPaths (initial) = %#v", gemPaths)
	}
	for i := 0; i < len(gemPaths); i++ {
		fullPath := filepath.Join(gemPaths[i], "lib", "vagrant", "version.rb")
		if _, err := os.Stat(fullPath); err != nil {
			if debug {
				log.Printf("launcher: bad gemPath += %s", fullPath)
			}

			gemPaths = append(gemPaths[:i], gemPaths[i+1:]...)
			i--
		}
	}
	if len(gemPaths) == 0 {
		fmt.Fprintf(os.Stderr, "Failed to find Vagrant!\n")
		os.Exit(1)
	}
	gemPath := gemPaths[len(gemPaths)-1]
	vagrantExecutable := filepath.Join(gemPath, "bin", "vagrant")
	if debug {
		log.Printf("launcher: gemPaths (final) = %#v", gemPaths)
		log.Printf("launcher: gemPath = %s", gemPath)
	}

	// Setup the CPP/LDFLAGS so that native extensions can be
	// properly compiled into the Vagrant environment.
	cppflags := "-I" + filepath.Join(embeddedDir, "include") +
		filepath.Join(embeddedDir, "include", "libxml2")
	ldflags := "-L" + filepath.Join(embeddedDir, "lib")
	if original := os.Getenv("CPPFLAGS"); original != "" {
		cppflags = original + " " + cppflags
	}
	if original := os.Getenv("LDFLAGS"); original != "" {
		ldflags = original + " " + ldflags
	}
	cflags := "-I" + filepath.Join(embeddedDir, "include") +
		filepath.Join(embeddedDir, "include", "libxml2")
	if original := os.Getenv("CFLAGS"); original != "" {
		cflags = original + " " + cflags
	}

	// Set the PATH to include the proper paths into our embedded dir
	path = os.Getenv("PATH")
	if runtime.GOOS == "windows" {
		path = fmt.Sprintf(
			"%s;%s;%s",
			filepath.Join(embeddedDir, "bin"),
			filepath.Join(embeddedDir, "gnuwin32", "bin"),
			path)
	} else {
		path = fmt.Sprintf("%s:%s",
			filepath.Join(embeddedDir, "bin"), path)
	}

	// Allow users to specify a custom SSL cert
	sslCertFile := os.Getenv("SSL_CERT_FILE")
	if sslCertFile == "" {
		sslCertFile = filepath.Join(embeddedDir, "cacert.pem")
	}

	newEnv := map[string]string{
		// Setup the environment to prefer our embedded dir over
		// anything the user might have setup on his/her system.
		"CPPFLAGS":      cppflags,
		"CFLAGS":        cflags,
		"GEM_HOME":      filepath.Join(embeddedDir, "gems"),
		"GEM_PATH":      filepath.Join(embeddedDir, "gems"),
		"GEMRC":         filepath.Join(embeddedDir, "etc", "gemrc"),
		"LDFLAGS":       ldflags,
		"PATH":          path,
		"SSL_CERT_FILE": sslCertFile,

		// Instruct nokogiri installations to use libraries provided
		// by the installer
		"NOKOGIRI_USE_SYSTEM_LIBRARIES": "true",

		// Environmental variables used by Vagrant itself
		"VAGRANT_EXECUTABLE":             vagrantExecutable,
		"VAGRANT_INSTALLER_ENV":          "1",
		"VAGRANT_INSTALLER_EMBEDDED_DIR": embeddedDir,
		"VAGRANT_INSTALLER_VERSION":      "2",
	}

	// Unset any RUBYOPT, we don't want this bleeding into our runtime
	newEnv["RUBYOPT"] = ""
	// Unset any RUBYLIB, we don't want this bleeding into our runtime
	newEnv["RUBYLIB"] = ""

	if runtime.GOOS == "darwin" {
		configure_args := "-Wl,rpath," + filepath.Join(embeddedDir, "lib")
		if original_configure_args := os.Getenv("CONFIGURE_ARGS"); original_configure_args != "" {
			configure_args = original_configure_args + " " + configure_args
		}
		newEnv["CONFIGURE_ARGS"] = configure_args
	}

	// Store the "current" environment so Vagrant can restore it when shelling
	// out.
	for _, value := range os.Environ() {
		idx := strings.IndexRune(value, '=')
		key := fmt.Sprintf("%s_%s", envPrefix, value[:idx])
		newEnv[key] = value[idx+1:]
	}
	if debug {
		keys := make([]string, 0, len(newEnv))
		for k, _ := range newEnv {
			keys = append(keys, k)
		}
		sort.Strings(keys)

		for _, k := range keys {
			log.Printf("launcher: env %q = %q", k, newEnv[k])
		}
	}

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

	// Prior to starting the command, we ignore interrupts. Vagrant itself
	// handles these, so the launcher should just wait until that exits.
	signal.Ignore(os.Interrupt)

	cmd := exec.Command(rubyPath)
	cmd.Args = make([]string, len(os.Args)+1)
	cmd.Args[0] = "ruby"
	cmd.Args[1] = vagrantExecutable
	copy(cmd.Args[2:], os.Args[1:])
	if debug {
		log.Printf("launcher: rubyPath = %s", rubyPath)
		log.Printf("launcher: args = %#v", cmd.Args)
	}

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
