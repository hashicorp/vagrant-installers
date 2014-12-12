all:
	gox -arch=386 -os=windows -output="launcher"

install: all
	cp launcher.exe ../modules/vagrant_substrate/files/vagrant.exe

.PHONY: all install
