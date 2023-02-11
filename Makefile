NAME = ghcr.io/mentalfs/backup-manager

.PHONY: build build-pull pull test release release-pull

build:
	docker build -t $(NAME):build .

build-pull:
	docker build --pull -t $(NAME):build .

pull:
	docker build --pull --target=build .

test:
	docker build --target=test .

release:
	docker build -t $(NAME):latest .

release-pull:
	docker build --pull -t $(NAME):latest .
