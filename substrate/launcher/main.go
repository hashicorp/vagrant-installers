package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
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

type VagrantConfig struct {
	Vagrant_version string
}

func readVagrantManifest(manifestPath string) VagrantConfig {
	raw, err := ioutil.ReadFile(manifestPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read Vagrant manifest file at %s: %s\n", manifestPath, err)
		os.Exit(1)
	}

	var conf VagrantConfig
	err = json.Unmarshal(raw, &conf)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to parse json in Vagrant manifest file at %s: %s\n", manifestPath, err)
		os.Exit(1)
	}
	return conf
}

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

	manifestPath := filepath.Join(embeddedDir, "manifest.json")
	vagrantConfig := readVagrantManifest(manifestPath)
	vagrantVersion := vagrantConfig.Vagrant_version

	if vagrantVersion == "" {
		log.Printf("launcher: Failed to set vagrant version from manifest file")
		os.Exit(1)
	}

	// Find the Vagrant gem
	filePath := filepath.Join(embeddedDir, "gems", vagrantVersion, "gems", "vagrant-*")
	gemPaths, err := filepath.Glob(filePath)
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
	cxxflags := ""
	cppflags := ""
	cflags := ""
	ldflags := ""
	configure_args := ""
	mingwArchDir := "x86_64-w64-mingw32"
	mingwDir := "mingw64"
	if runtime.GOOS == "windows" {
		// Check if we are in a 32bit or 64bit install
		mingwTestPath := filepath.Join(embeddedDir, "mingw64")
		if _, err := os.Stat(mingwTestPath); err != nil {
			if debug {
				log.Printf("launcher: detected 32bit Windows installation")
			}
			mingwDir = "mingw32"
			mingwArchDir = "i686-w64-mingw32"
		}
		cflags = "-I" + filepath.Join(embeddedDir, mingwDir, mingwArchDir, "include") +
			" -I" + filepath.Join(embeddedDir, mingwDir, "include") +
			" -I" + filepath.Join(embeddedDir, "usr", "include")
		cppflags = "-I" + filepath.Join(embeddedDir, mingwDir, mingwArchDir, "include") +
			" -I" + filepath.Join(embeddedDir, mingwDir, "include") +
			" -I" + filepath.Join(embeddedDir, "usr", "include")
		ldflags = "-L" + filepath.Join(embeddedDir, mingwDir, mingwArchDir, "lib") +
			" -L" + filepath.Join(embeddedDir, mingwDir, "lib") +
			" -L" + filepath.Join(embeddedDir, "usr", "lib")
	} else {
		cppflags = "-I" + filepath.Join(embeddedDir, "include") +
			" -I" + filepath.Join(embeddedDir, "include", "libxml2")
		ldflags = "-L" + filepath.Join(embeddedDir, "lib") + " -L" +
			filepath.Join(embeddedDir, "lib64")
		cflags = "-I" + filepath.Join(embeddedDir, "include") +
			" -I" + filepath.Join(embeddedDir, "include", "libxml2")
	}

	// Include any original flags
	if original := os.Getenv("CFLAGS"); original != "" {
		cflags = original + " " + cflags
	}
	if original := os.Getenv("CPPFLAGS"); original != "" {
		cppflags = original + " " + cppflags
	}
	if original := os.Getenv("LDFLAGS"); original != "" {
		ldflags = original + " " + ldflags
	}
	if original := os.Getenv("CXXFLAGS"); original != "" {
		cxxflags = original + " " + cxxflags
	}
	if original := os.Getenv("CONFIGURE_ARGS"); original != "" {
		configure_args = original + " " + configure_args
	}

	// Allow users to specify a custom SSL cert
	sslCertFile := os.Getenv("SSL_CERT_FILE")
	if sslCertFile == "" {
		sslCertFile = filepath.Join(embeddedDir, "cacert.pem")
	}
	curlCaBundle := os.Getenv("CURL_CA_BUNDLE")
	if curlCaBundle == "" {
		curlCaBundle = filepath.Join(embeddedDir, "cacert.pem")
	}

	newEnv := map[string]string{
		// Setup the environment to prefer our embedded dir over
		// anything the user might have setup on their system.
		"CONFIGURE_ARGS": configure_args,
		"CXXFLAGS":       cxxflags,
		"CPPFLAGS":       cppflags,
		"CFLAGS":         cflags,
		"GEM_HOME":       filepath.Join(embeddedDir, "gems", vagrantVersion),
		"GEM_PATH":       filepath.Join(embeddedDir, "gems", vagrantVersion),
		"GEMRC":          filepath.Join(embeddedDir, "etc", "gemrc"),
		"LDFLAGS":        ldflags,
		"PATH":           path,
		"SSL_CERT_FILE":  sslCertFile,
		"CURL_CA_BUNDLE": curlCaBundle,

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
		newEnv["CONFIGURE_ARGS"] = newEnv["CONFIGURE_ARGS"] +
			" -Wl,rpath," + filepath.Join(embeddedDir, "lib")
	}

	// Set pkg-config paths
	if runtime.GOOS == "windows" {
		newEnv["PKG_CONFIG_PATH"] = filepath.Join(embeddedDir, mingwDir, "lib", "pkgconfig") +
			":" + filepath.Join(embeddedDir, "usr", "lib", "pkgconfig")
	} else {
		newEnv["PKG_CONFIG_PATH"] = filepath.Join(embeddedDir, "lib", "pkgconfig") +
			":" + filepath.Join(embeddedDir, "lib64", "pkgconfig")
	}

	// Detect custom windows environment (cygwin/msys/etc)
	if runtime.GOOS == "windows" {
		// If VAGRANT_DETECTED_OS is provided by the user let that value
		// take precedence over any discovery.
		if os.Getenv("VAGRANT_DETECTED_OS") != "" {
			newEnv["VAGRANT_DETECTED_OS"] = os.Getenv("VAGRANT_DETECTED_OS")
		} else if os.Getenv("OSTYPE") != "" {
			newEnv["VAGRANT_DETECTED_OS"] = os.Getenv("OSTYPE")
		}
		if os.Getenv("VAGRANT_DETECTED_ARCH") != "" {
			newEnv["VAGRANT_DETECTED_ARCH"] = os.Getenv("VAGRANT_DETECTED_ARCH")
		}
		if os.Getenv("OSTYPE") != "" && (newEnv["VAGRANT_DETECTED_OS"] == "" || newEnv["VAGRANT_DETECTED_ARCH"] == "") {
			unameOutput, err := exec.Command("uname", "-om").Output()
			if err == nil {
				uname := strings.Replace(fmt.Sprintf("%s", unameOutput), "\n", "", -1)
				if newEnv["VAGRANT_DETECTED_ARCH"] == "" {
					if strings.Contains(uname, "686") {
						newEnv["VAGRANT_DETECTED_ARCH"] = "32"
					} else {
						newEnv["VAGRANT_DETECTED_ARCH"] = "64"
					}
				}
				detectedOsParts := strings.Split(uname, " ")
				if newEnv["VAGRANT_DETECTED_OS"] == "" && detectedOsParts[1] != "" {
					newEnv["VAGRANT_DETECTED_OS"] = strings.ToLower(detectedOsParts[1])
				}
			}
		}

		if debug && newEnv["VAGRANT_DETECTED_OS"] != "" {
			log.Printf("launcher: windows detected OS - %s", newEnv["VAGRANT_DETECTED_OS"])
		}
		if debug && newEnv["VAGRANT_DETECTED_ARCH"] != "" {
			log.Printf("launcher: windows detected arch - %s", newEnv["VAGRANT_DETECTED_ARCH"])
		}
	} else {
		// Check our cert files to ensure they actually exist. If not
		// then remove them from the new environment.
		if _, ok := newEnv["SSL_CERT_FILE"]; ok {
			if _, err := os.Stat(newEnv["SSL_CERT_FILE"]); err != nil {
				if debug {
					log.Printf("launcher: SSL_CERT_FILE not found, removing - %s", newEnv["SSL_CERT_FILE"])
				}
				delete(newEnv, "SSL_CERT_FILE")
			}
		}
		if _, ok := newEnv["CURL_CA_BUNDLE"]; ok {
			if _, err := os.Stat(newEnv["CURL_CA_BUNDLE"]); err != nil {
				if debug {
					log.Printf("launcher: CURL_CA_BUNDLE not found, removing - %s", newEnv["CURL_CA_BUNDLE"])
				}
				delete(newEnv, "CURL_CA_BUNDLE")
			}
		}
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

	// Determine the path to Ruby and then start the Vagrant process
	rubyPath := filepath.Join(embeddedDir, "bin", "ruby")
	if runtime.GOOS == "windows" {
		rubyPath = filepath.Join(embeddedDir, mingwDir, "bin", "ruby") + ".exe"
	}
	_, err = os.Stat(rubyPath)
	if err != nil {
		if debug {
			log.Printf("launcher: no embedded ruby found. falling back to path provided.")
		}
		rubyPath = "ruby"
	}

	// Prior to starting the command, we ignore interrupts. Vagrant itself
	// handles these, so the launcher should just wait until that exits.
	signal.Ignore(os.Interrupt)

	var cmd *exec.Cmd

	// Set the PATH to include the proper paths into our embedded dir
	path = os.Getenv("PATH")
	preferSystem := os.Getenv("VAGRANT_PREFER_SYSTEM_BIN") != "" && os.Getenv("VAGRANT_PREFER_SYSTEM_BIN") != "0"
	if runtime.GOOS == "windows" {
		if preferSystem {
			if debug {
				log.Printf("launcher: path modification will prefer system bins.")
			}
			if os.Getenv("VAGRANT_DISABLE_WINCURL") != "" {
				path = fmt.Sprintf(
					"%s;%s;%s;%s",
					path,
					filepath.Join(embeddedDir, mingwDir, "bin"),
					filepath.Join(embeddedDir, "usr", "bin"),
					filepath.Join(embeddedDir, "bin"))
			} else {
				path = fmt.Sprintf(
					"%s;%s;%s;%s",
					path,
					filepath.Join(embeddedDir, "bin"),
					filepath.Join(embeddedDir, mingwDir, "bin"),
					filepath.Join(embeddedDir, "usr", "bin"))
			}
		} else {
			if os.Getenv("VAGRANT_DISABLE_WINCURL") != "" {
				path = fmt.Sprintf(
					"%s;%s;%s;%s",
					filepath.Join(embeddedDir, mingwDir, "bin"),
					filepath.Join(embeddedDir, "usr", "bin"),
					filepath.Join(embeddedDir, "bin"),
					path)
			} else {
				path = fmt.Sprintf(
					"%s;%s;%s;%s",
					filepath.Join(embeddedDir, "bin"),
					filepath.Join(embeddedDir, mingwDir, "bin"),
					filepath.Join(embeddedDir, "usr", "bin"),
					path)
			}
		}
	} else {
		if preferSystem {
			if debug {
				log.Printf("launcher: path modification will prefer system bins.")
			}
			path = fmt.Sprintf("%s:%s",
				path, filepath.Join(embeddedDir, "bin"))
		} else {
			path = fmt.Sprintf("%s:%s",
				filepath.Join(embeddedDir, "bin"), path)
		}
	}
	newEnv["PATH"] = path

	// Set all the environmental variables
	for k, v := range newEnv {
		if err := os.Setenv(k, v); err != nil {
			fmt.Fprintf(os.Stderr, "Error setting env var %s: %s\n", k, err)
			os.Exit(1)
		}
	}

	cmd = exec.Command(rubyPath)
	cmd.Args = make([]string, len(os.Args)+1)
	cmd.Args[0] = "ruby"
	cmd.Args[1] = vagrantExecutable
	copy(cmd.Args[2:], os.Args[1:])
	if debug {
		log.Printf("launcher: rubyPath = %s", rubyPath)
	}

	if debug {
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
