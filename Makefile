NAME = backup-manager

.PHONY: build pull test release

build:
	docker build -t $(NAME):build .

pull:
	docker build --pull --target=test .

test:
	docker build --progress=plain --no-cache-filter=test-base --target=test .

release:
	docker build --pull -t $(NAME):latest .
