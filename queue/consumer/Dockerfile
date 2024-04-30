# FROM python:3.9-slim-bullseye AS builder
FROM python:3.10-slim-bullseye AS builder

# Install required systems libraries
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN pip install -U pip
COPY requirements.txt ./
RUN pip install -r requirements.txt --force-reinstall

# Get service files
ADD consumer.py ./
RUN mv consumer.py service.py

# VERSION INFORMATION
ARG GIT_TAG ???
ARG GIT_COMMIT ???
ARG BUILD_DATE ???

ENV IVCAP_SERVICE_VERSION $GIT_TAG
ENV IVCAP_SERVICE_COMMIT $GIT_COMMIT
ENV IVCAP_SERVICE_BUILD $BUILD_DATE

ENTRYPOINT ["python", "/app/service.py"]
