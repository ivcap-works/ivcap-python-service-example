FROM python:3.9-slim-buster AS builder

# Local path to IVCAP Python SDK. See:
#
#     https://github.com/reinventingscience/ivcap-sdk-python
#
ARG SDK_PATH ???
ARG SDK_COMMIT=HEAD

# Install required systems libraries.
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install Python build system.
RUN pip install poetry

# Create distribution wheel.
COPY $SDK_PATH /usr/local/src/ivcap-sdk-python/
RUN cd /usr/local/src/ivcap-sdk-python/ && \
  git checkout ${SDK_COMMIT} && \
  cd sdk_service &&\
  make build build




FROM python:3.9-slim-buster

# Copy build files for IVCAP Python SDK and service example.
WORKDIR /app
COPY --from=builder /usr/local/src/ivcap-sdk-python/sdk_service/dist ./ivcap_sdk_service
COPY requirements.txt ./
RUN sed -i '\|git+ssh://git@github.com/reinventingscience/|d' requirements.txt

RUN cd ./ivcap_sdk_service && \
  pip install ivcap_sdk_service*.whl && \
  cd ../ && \
  pip install -r requirements.txt

# Get service files
ADD img_test_service.py CaveatBrush-Regular.ttf ./
RUN mv img_test_service.py service.py

# VERSION INFORMATION
ARG GIT_TAG ???
ARG GIT_COMMIT ???
ARG BUILD_DATE ???

ENV IVCAP_SERVICE_VERSION $GIT_TAG
ENV IVCAP_SERVICE_COMMIT $GIT_COMMIT
ENV IVCAP_SERVICE_BUILD $BUILD_DATE

# Command to run
RUN mkdir -p /data/in /data/out
ENTRYPOINT ["python", "/app/service.py"]