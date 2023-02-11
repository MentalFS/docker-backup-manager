NAME = mentalfs/backup-manager
VERSION = latest

.PHONY: build

build:
	docker build --pull -t $(NAME):$(VERSION) .
