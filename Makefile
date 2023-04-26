VERSION  = $(shell git describe --abbrev=0 --tags)
IMAGE_NAME  = base-image
IMAGE_PATH = flyimg/$(IMAGE_NAME):$(VERSION)

build:
	docker build -t $(IMAGE_NAME) .

push: build
	docker tag $(IMAGE_NAME) $(IMAGE_PATH)
	docker push $(IMAGE_PATH)
	@echo "PUSHED ${IMAGE_PATH}"
