SERVICE_CONTAINER_NAME=simple-python-service
SERVICE_TITLE=Simple Python Service

SERVICE_FILE=img_test_service.py

PROVIDER_NAME=ivcap.test
# ACCOUNT_NAME=${PROVIDER_NAME}

# PROVIDER_ID=$(ivcap context get --provider-id)
# ACCOUNT_ID=$(ivcap context get --account-id)

# don't foget to login 'az acr login --name cipmain'
AZ_DOCKER_REGISTRY=cipmain.azurecr.io
DOCKER_REGISTRY=localhost:5000

SERVICE_ID:=cayp:service:$(shell python3 -c 'import uuid; print(uuid.uuid5(uuid.NAMESPACE_DNS, \
        "${PROVIDER_NAME}" + "${SERVICE_CONTAINER_NAME}"));'):${SERVICE_CONTAINER_NAME}

GIT_COMMIT := $(shell git rev-parse --short HEAD)
GIT_TAG := $(shell git describe --abbrev=0 --tags ${TAG_COMMIT} 2>/dev/null || true)

DOCKER_NAME=$(shell echo ${SERVICE_CONTAINER_NAME} | sed -E 's/-/_/g')
DOCKER_TAG=$(shell echo ${PROVIDER_NAME} | sed -E 's/[-:]/_/g')/${DOCKER_NAME}:${GIT_COMMIT}
DOCKER_DEPLOY=${DOCKER_REGISTRY}/${DOCKER_TAG}

PROJECT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

TMP_DIR=/tmp
DOCKER_LOCAL_DATA_DIR=/tmp/data
IMG_URL=https://juststickers.in/wp-content/uploads/2016/07/go-programming-language.png

run:
	mkdir -p ${PROJECT_DIR}/data
	python ${SERVICE_FILE} \
	  --msg "$(shell date "+%d/%m-%H:%M:%S")" \
		--img-url ${IMG_URL} \
		--ivcap:out-dir ${PROJECT_DIR}/data
	@echo ">>> Output should be in '${PROJECT_DIR}/data'"

docker-run: #docker-build
	# If running Minikube, the 'data' directory needs to be created inside minikube
	mkdir -p ${DOCKER_LOCAL_DATA_DIR}/in ${DOCKER_LOCAL_DATA_DIR}/out
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-v ${DOCKER_LOCAL_DATA_DIR}:/data \
		${DOCKER_NAME} \
		--ivcap:in-dir /data/in \
		--ivcap:out-dir /data/out \
		--msg "$(shell date "+%d/%m-%H:%M:%S")" \
		--img-url ${IMG_URL}
	@echo ">>> Output should be in '${DOCKER_LOCAL_DATA_DIR}' (might be inside minikube)"

docker-run-nuitka:
	make DOCKER_NAME=simple_python_service-nuitka run
	
docker-debug: #docker-build
	# If running Minikube, the 'data' directory needs to be created inside minikube
	mkdir -p ${DOCKER_LOCAL_DATA_DIR}/in ${DOCKER_LOCAL_DATA_DIR}/out
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-v ${DOCKER_LOCAL_DATA_DIR}:/data \
		--entrypoint bash \
		${DOCKER_NAME}

docker-build:
	@echo "Building docker image ${DOCKER_NAME}"
	docker build \
		--build-arg GIT_COMMIT=${GIT_COMMIT} \
		--build-arg GIT_TAG=${GIT_TAG} \
		--build-arg BUILD_DATE="$(shell date)" \
		-t ${DOCKER_NAME} \
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

docker-publish: docker-build
	@echo "====> If 'unauthorized: authentication required' log into ACR with 'az acr login --name cipmain'"
	docker tag ${DOCKER_NAME} ${DOCKER_DEPLOY}
	docker push ${DOCKER_DEPLOY}

service-description:
	python ${SERVICE_FILE} --ivcap:print-service-description

service-register: FORCE
	python infer_service.py --ivcap:print-service-description \
	| sed  -E 's|@SERVICE_ID@|${SERVICE_ID}|g' \
	| sed  -E 's|@PROVIDER_ID@|${PROVIDER_ID}|g' \
	| sed  -E 's|@ACCOUNT_ID@|${ACCOUNT_ID}|g' \
	| sed  -E 's|@CONTAINER@|${DOCKER_DEPLOY}|g' \
	| ivcap service update --create ${SERVICE_ID} --format yaml -f -

clean:
	rm -rf ${PROJECT_DIR}/$(shell echo ${SERVICE_FILE} | cut -d. -f1 ).dist
	rm -rf ${PROJECT_DIR}/$(shell echo ${SERVICE_FILE} | cut -d. -f1 ).build
	rm -rf ${PROJECT_DIR}/cache ${PROJECT_DIR}/data

docker-run-data-proxy: #docker-build
	rm -rf /tmp/order1
	mkdir -p /tmp/order1/in 
	mkdir -p /tmp/order1/out 
	docker run -it \
		-e IVCAP_INSIDE_CONTAINER="Yes" \
		-e IVCAP_ORDER_ID=ivcap:order:0000 \
		-e IVCAP_NODE_ID=n0 \
		-e http_proxy=http://192.168.68.118:8888 \
	  -e https_proxy=http://192.168.68.118:8888 \
		-e IVCAP_STORAGE_URL=http://artifact.local \
	  -e IVCAP_CACHE_URL=http://cache.local \
		-v ${DOCKER_LOCAL_DATA_DIR}:/data \
		${DOCKER_NAME} \
		--ivcap:in-dir /data/in \
		--ivcap:out-dir /data/out \
		--model deploy2.tgz \
		--image jpg_small/FUL1_t3_0m-small.jpg
	
FORCE:
