# Vagrant Launcher

This is the binary that is shipped with the substrate that
launches Vagrant. The reason this is written in Go is mostly
out of convenience. Before, we would have to maintain shell and
batch scripts that had to handle all sorts of edge cases.

Now, we have a single Go binary that can launch on any platform
with any shell (on Windows).
