NAME = mentalfs/backup-manager
VERSION = latest

.PHONY: release release-pull pull test

release:
	docker build -t $(NAME):$(VERSION) .

release-pull:
	docker build --pull -t $(NAME):$(VERSION) .

pull: release-pull

test:
	docker build --target=test .
