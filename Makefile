IMAGE := quay.io/skupper/simple-prom-metrics

.PHONY: build
build:
	docker build -t ${IMAGE} .

.PHONY: run
run: build
	docker run -p 8080:8080 ${IMAGE}

# Prerequisite: docker login quay.io
.PHONY: push
push: build
	docker push ${IMAGE}
