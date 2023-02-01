FROM python:3.9-slim-buster AS builder

# Install required systems libraries
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  git ssh && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Setup for access to private git repo
RUN mkdir -p /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
ADD .ssh/id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

WORKDIR /app
COPY requirements.txt ./
RUN pip install -U pip
RUN pip install -r requirements.txt

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