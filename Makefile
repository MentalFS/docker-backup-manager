NAME = mentalfs/backup-manager
VERSION = SNAPSHOT

.PHONY: build

build:
	docker build --pull -t $(NAME):$(VERSION) .
