.PHONY: bin/launcher
bin/launcher:
	go build -o ./bin/vagrant ./substrate/launcher

.PHONY: bin/launcher/windows
bin/launcher/windows:
	GOOS=windows GOARCH=amd64 $(MAKE) bin/launcher

.PHONY: bin/launcher/darwin-amd64
bin/launcher/darwin-amd64:
	GOOS=darwin GOARCH=amd64 $(MAKE) bin/launcher

.PHONY: bin/launcher/darwin-arm64
bin/launcher/darwin-arm64:
	GOOS=darwin GOARCH=arm64 $(MAKE) bin/launcher

.PHONY: bin/launcher/linux-amd64
bin/launcher/linux-amd64:
	GOOS=linux GOARCH=amd64 $(MAKE) bin/launcher

.PHONY: bin/launcher/linux-386
bin/launcher/linux-386:
	GOOS=linux GOARCH=386 $(MAKE) bin/launcher
