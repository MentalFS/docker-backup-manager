NAME = backup-manager

.PHONY: build build-pull build-only pull test release release-pull

build:
	docker build -t $(NAME):build .

build-only:
	docker build -t $(NAME):build --target=build .

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
