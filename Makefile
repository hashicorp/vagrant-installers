.PHONY: bin/launcher
bin/launcher:
	go build -o ./bin/launcher ./substrate/launcher

.PHONY: bin/launcher/windows
bin/launcher/windows:
	$(MAKE) bin/launcher/windows-x86_64
	$(MAKE) bin/launcher/windows-386

.PHONY: bin/launcher/windows-x86_64
bin/launcher/windows-x86_64:
	GOOS=windows GOARCH=amd64 go build -o ./bin/launcher-windows_x86_64 ./substrate/launcher

.PHONY: bin/launcher/windows-386
bin/launcher/windows-386:
	GOOS=windows GOARCH=386 go build -o ./bin/launcher-windows_386 ./substrate/launcher

.PHONY: bin/launcher/darwin
bin/launcher/darwin:
	$(MAKE) bin/launcher/darwin-x86_64
	$(MAKE) bin/launcher/darwin-arm64

.PHONY: bin/launcher/darwin-x86_64
bin/launcher/darwin-x86_64:
	GOOS=darwin GOARCH=amd64 go build -o ./bin/launcher-darwin_x86_64 ./substrate/launcher

.PHONY: bin/launcher/darwin-arm64
bin/launcher/darwin-arm64:
	GOOS=darwin GOARCH=arm64 go build -o ./bin/launcher-darwin_arm64 ./substrate/launcher

.PHONY: bin/launcher/linux
bin/launcher/linux:
	$(MAKE) bin/launcher/linux-x86_64
	$(MAKE) bin/launcher/linux-386

.PHONY: bin/launcher/linux-x86_64
bin/launcher/linux-x86_64:
	GOOS=linux GOARCH=amd64 go build -o ./bin/launcher-linux_x86_64 ./substrate/launcher

.PHONY: bin/launcher/linux-386
bin/launcher/linux-386:
	GOOS=linux GOARCH=386 go build -o ./bin/launcher-linux_386 ./substrate/launcher

.PHONY: bin/launcher/all
bin/launcher/all:
	$(MAKE) bin/launcher/windows-x86_64
	$(MAKE) bin/launcher/windows-386
	$(MAKE) bin/launcher/darwin-x86_64
	$(MAKE) bin/launcher/darwin-arm64
	$(MAKE) bin/launcher/linux-x86_64
	$(MAKE) bin/launcher/linux-386

.PHONY: clean
clean:
	rm -f ./bin/launcher*
