# Description: Makefile for the consumer service

SERVICE_CONTAINER_NAME=queue-consumer-service
SERVICE_TITLE=Simple Queue Consumer Service
SERVICE_FILE=consumer.py
PROVIDER_NAME=ivcap.kube

SERVICE_ID:=ivcap:service:$(shell python3 -c 'import uuid; print(uuid.uuid5(uuid.NAMESPACE_DNS, \
        "${PROVIDER_NAME}" + "${SERVICE_CONTAINER_NAME}"));'):${SERVICE_CONTAINER_NAME}

GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)

DOCKER_REGISTRY=localhost:5000
DOCKER_NAME=$(shell echo ${SERVICE_CONTAINER_NAME} | sed -E 's/-/_/g')
DOCKER_VERSION=${GIT_COMMIT}
DOCKER_TAG=$(shell echo ${PROVIDER_NAME} | sed -E 's/[-:]/_/g')/${DOCKER_NAME}:${DOCKER_VERSION}
DOCKER_DEPLOY=${DOCKER_REGISTRY}/${DOCKER_TAG}

PROJECT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

echo:
	@echo "SERVICE_ID=${SERVICE_ID}"
	@echo "DOCKER_NAME=${DOCKER_NAME}"
	@echo "DOCKER_VERSION=${DOCKER_VERSION}"
	@echo "DOCKER_TAG=${DOCKER_TAG}"
	@echo "DOCKER_DEPLOY=${DOCKER_DEPLOY}"
	@echo "PROJECT_DIR=${PROJECT_DIR}"

docker-build:
	@echo "Building docker image ${DOCKER_NAME}"
	docker build \
		--build-arg GIT_COMMIT=${GIT_COMMIT} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg BUILD_DATE="$(shell date)" \
		--no-cache \
		-t ${DOCKER_NAME} \
		-f ${PROJECT_DIR}/Dockerfile \
		${PROJECT_DIR} ${DOCKER_BILD_ARGS}
	@echo "\nFinished building docker image ${DOCKER_NAME}\n"

docker-publish: docker-build
	docker tag ${DOCKER_NAME} ${DOCKER_DEPLOY}
	docker push ${DOCKER_DEPLOY}

service-description:
	env IVCAP_PROVIDER_ID=$(shell ivcap context get provider-id) \
		IVCAP_ACCOUNT_ID=$(shell ivcap context get account-id) \
		IVCAP_CONTAINER=${DOCKER_DEPLOY} \
	python ${SERVICE_FILE} --ivcap:print-service-description

service-register: docker-publish
	env IVCAP_PROVIDER_ID=$(shell ivcap context get provider-id) \
		IVCAP_ACCOUNT_ID=$(shell ivcap context get account-id) \
		IVCAP_CONTAINER=${DOCKER_DEPLOY} \
	python ${SERVICE_FILE} --ivcap:print-service-description \
	| ivcap service update --create ${SERVICE_ID} --format yaml -f - --timeout 600
