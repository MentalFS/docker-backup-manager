NAME = mentalfs/backup-manager
VERSION = SNAPSHOT

.PHONY: build

build:
	docker build -t $(NAME):$(VERSION) .
