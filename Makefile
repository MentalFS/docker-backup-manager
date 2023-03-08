NAME = backup-manager

.PHONY: build pull test release

build:
	docker build -t $(NAME):build .

pull:
	docker build --pull -t $(NAME):download --target=download .
	docker build --pull --target=build .

test:
	docker build --target=test .

release:
	docker build --pull -t $(NAME):latest .
