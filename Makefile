SERVICE_NAME=hello-world-python
SERVICE_TITLE=Hello World - Python

SERVICE_FILE=hello_world_service.py

GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)
VERSION="${GIT_TAG}|${GIT_COMMIT}|$(shell date -Iminutes)"

DOCKER_USER="$(shell id -u):$(shell id -g)"
DOCKER_DOMAIN=$(shell echo ${PROVIDER_NAME} | sed -E 's/[-:]/_/g')
DOCKER_NAME=$(shell echo ${SERVICE_NAME} | sed -E 's/-/_/g')
DOCKER_VERSION=${GIT_COMMIT}
DOCKER_TAG=${DOCKER_NAME}:${DOCKER_VERSION}
DOCKER_TAG_LOCAL=${DOCKER_NAME}:latest

PROJECT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TARGET_PLATFORM := linux/amd64

TMP_DIR=/tmp
DOCKER_LOCAL_DATA_DIR=/tmp/DATA

#IMG_URL=https://juststickers.in/wp-content/uploads/2016/07/go-programming-language.png
#IMG_URL=https://dwglogo.com/wp-content/uploads/2017/08/gopher_hanging_left_purple.png
IMG_URL=https://wallpaperaccess.com/full/4482737.png
IMAGE_ARTIFACT=urn:ivcap:artifact:07793994-bbff-49d5-979b-0843b6b4093c

GITHUB_USER_HOST?=git@github.com
SDK_CLONE_RELATIVE=.ivcap-sdk-python
SDK_CLONE_ABSOLUTE=${PROJECT_DIR}/.ivcap-sdk-python
SDK_COMMIT?=HEAD

run:
	mkdir -p ${PROJECT_DIR}/DATA
	python ${SERVICE_FILE} \
		--msg "$(shell date "+%d/%m-%H:%M:%S")" \
		--background-img ${IMG_URL} \
		--ivcap:out-dir ${PROJECT_DIR}/DATA
	@echo ">>> Output should be in '${PROJECT_DIR}/DATA'"

build:
	pip install -r requirements.txt

docker-run: #docker-build
	@echo ""
	@echo ">>>>>>> On Mac, please ensure that this directory is mounted into minikube (if that's what you are using)"
	@echo ">>>>>>>    minikube mount ${PROJECT_DIR}:${PROJECT_DIR}"
	@echo ""
	mkdir -p ${PROJECT_DIR}/DATA/run && rm -rf ${PROJECT_DIR}/DATA/run/*
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-v ${PROJECT_DIR}:/data/in \
		-v ${PROJECT_DIR}/DATA/run:/data/out \
		-v ${PROJECT_DIR}/DATA/run:/app/cache \
		--user ${DOCKER_USER} \
		${DOCKER_NAME} \
		--msg "$(shell date "+%d/%m-%H:%M:%S")" \
		--background-img ${IMG_URL} \
		--ivcap:out-dir /app/cache
	@echo ">>> Output should be in '${DOCKER_LOCAL_DATA_DIR}' (might be inside minikube)"

docker-run-nuitka:
	make DOCKER_NAME=simple_python_service-nuitka docker-run

docker-debug: #docker-build
	# If running Minikube, the 'data' directory needs to be created inside minikube
	mkdir -p ${DOCKER_LOCAL_DATA_DIR}/in ${DOCKER_LOCAL_DATA_DIR}/out
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-v ${PROJECT_DIR}:/data\
		--entrypoint bash \
		${DOCKER_NAME}

docker-build:
	@echo "Building docker image ${DOCKER_NAME}"
	docker build \
		-t ${DOCKER_TAG} \
		--platform=${TARGET_PLATFORM} \
		--build-arg GIT_COMMIT=${GIT_COMMIT} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg BUILD_DATE="$(shell date)" \
		-f ${PROJECT_DIR}/Dockerfile \
		${PROJECT_DIR} ${DOCKER_BILD_ARGS}
	@echo "\nFinished building docker image ${DOCKER_NAME}\n"

docker-build-nuitka:
	@echo "Building docker image ${DOCKER_NAME}"
	docker build \
		--build-arg GIT_COMMIT=${GIT_COMMIT} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg BUILD_DATE="$(shell date)" \
		-t ${DOCKER_NAME}-nuitka \
		-f ${PROJECT_DIR}/Dockerfile.nuitka \
		${PROJECT_DIR} ${DOCKER_BILD_ARGS}
	@echo "\nFinished building docker image ${DOCKER_NAME}\n"

SERVICE_IMG := ${DOCKER_DEPLOY}
PUSH_FROM := ""

docker-publish:
	@echo "Publishing docker image '${DOCKER_TAG}'"
	docker tag ${DOCKER_TAG_LOCAL} ${DOCKER_TAG}
	sleep 1

	@$(eval size:=$(shell docker inspect ${DOCKER_TAG} --format='{{.Size}}' | tr -cd '0-9'))
	@$(eval imageSize:=$(shell expr ${size} + 0 ))
	@echo "ImageSize is ${imageSize}"
	@if [ ${imageSize} -gt 2000000000 ]; then \
		set -e ; \
		echo "preparing upload from local registry"; \
		if [ -z "$(shell docker ps -a -q -f name=registry-2)" ]; then \
			echo "running local registry-2"; \
			docker run --restart always -d -p 8081:5000 --name registry-2 registry:2 ; \
		fi; \
		docker tag ${DOCKER_TAG} localhost:8081/${DOCKER_TAG} ; \
		docker push localhost:8081/${DOCKER_TAG} ; \
		$(MAKE) PUSH_FROM="localhost:8081/" docker-publish-common ; \
	else \
		$(MAKE) PUSH_FROM="--local " docker-publish-common; \
	fi

docker-publish-common:
	@$(eval log:=$(shell ivcap package push --force ${PUSH_FROM}${DOCKER_TAG} | tee /dev/tty))
	@$(eval registry := $(shell echo ${DOCKER_REGISTRY} | cut -d'/' -f1))
	@$(eval SERVICE_IMG := $(shell echo ${log} | sed -E "s/.*(${registry}.*) pushed.*/\1/"))
	@if [ ${SERVICE_IMG} == "" ] || [ ${SERVICE_IMG} == ${DOCKER_DEPLOY} ]; then \
		echo "service package push failed"; \
		exit 1; \
	fi

service-description:
	$(eval account_id=$(shell ivcap context get account-id))
	@if [[ ${account_id} != urn:ivcap:account:* ]]; then echo "ERROR: No IVCAP account found"; exit -1; fi
	$(eval service_id:=urn:ivcap:service:$(shell python3 -c 'import uuid; print(uuid.uuid5(uuid.NAMESPACE_DNS, \
        "${SERVICE_NAME}" + "${account_id}"));'))
	$(eval image:=$(shell ivcap package list ${DOCKER_TAG}))
	@if [[ -z "${image}" ]]; then echo "ERROR: No uploaded docker image '${DOCKER_TAG}' found"; exit -1; fi
	@echo "ServiceID: ${service_id}"
	env IVCAP_SERVICE_ID=${service_id} \
		IVCAP_ACCOUNT_ID=${account_id} \
		IVCAP_CONTAINER=${image} \
	python ${SERVICE_FILE} --ivcap:print-service-description

service-register: docker-publish
	$(eval account_id=$(shell ivcap context get account-id))
	@if [[ ${account_id} != urn:ivcap:account:* ]]; then echo "ERROR: No IVCAP account found"; exit -1; fi
	$(eval service_id:=urn:ivcap:service:$(shell python3 -c 'import uuid; print(uuid.uuid5(uuid.NAMESPACE_DNS, \
        "${SERVICE_NAME}" + "${account_id}"));'))
	$(eval image:=$(shell ivcap package list ${DOCKER_TAG}))
	@if [[ -z "${image}" ]]; then echo "ERROR: No uploaded docker image '${DOCKER_TAG}' found"; exit -1; fi
	@echo "ServiceID: ${service_id}"
	env IVCAP_SERVICE_ID=${service_id} \
		IVCAP_ACCOUNT_ID=${account_id} \
		IVCAP_CONTAINER=${image} \
	python ${SERVICE_FILE} --ivcap:print-service-description \
	| ivcap service update --create ${SERVICE_ID} --format yaml -f - --timeout 600

clean:
	rm -rf ${PROJECT_DIR}/$(shell echo ${SERVICE_FILE} | cut -d. -f1 ).dist
	rm -rf ${PROJECT_DIR}/$(shell echo ${SERVICE_FILE} | cut -d. -f1 ).build
	rm -rf ${PROJECT_DIR}/cache ${PROJECT_DIR}/DATA

# IGNORE - USED ONLY FOR INTERNAL DEBUGGING
docker-run-data-proxy: #docker-build
	rm -rf /tmp/order1
	mkdir -p /tmp/order1/in
	mkdir -p /tmp/order1/out
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="Yes" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-e http_proxy=http://192.168.68.102:9999 \
		-e https_proxy=http://192.168.68.102:9999 \
		-e IVCAP_STORAGE_URL=http://artifact.local \
		-e IVCAP_CACHE_URL=http://cache.local \
		-e IVCAP_DATA_PROXY_RETRIES=20 \
		-e IVCAP_DATA_PROXY_DELAY=10 \
		${DOCKER_NAME} \
		--msg "$(shell date "+%d/%m-%H:%M:%S")" \
		--background-img urn:${IMG_URL}

FORCE:
