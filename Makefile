NAME = mentalfs/backup-manager
VERSION = latest

.PHONY: build pull

build:
	docker build -t $(NAME):$(VERSION) .

build-pull:
	docker build --pull -t $(NAME):$(VERSION) .
pull: build-pull
