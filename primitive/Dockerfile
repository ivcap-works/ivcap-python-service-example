##
## Copyright (c) 2023 Commonwealth Scientific and Industrial Research Organisation (CSIRO). All rights reserved.
## Use of this source code is governed by a BSD-style license that can be
## found in the LICENSE file. See the AUTHORS file for names of contributors.
##

# This Dockerfile builds a container image for running a Python service that uses the primitive package.
# The container has two stages:
#   1. Build the Go binary and install the primitive package.
#   2. Create a lightweight image with the Go binary and Python script.
# The Python script and requirements file are copied into the container, and the Python packages are installed.
# Finally, the Python script is run as the entrypoint of the container.

# Stage 1: Build the Go binary
FROM golang:1.21-alpine AS build

# Install Git. Required for fetching the dependencies.
RUN apk add --no-cache git=2.45.2-r0

ENV GOOS=linux
ENV GO111MODULE=on

# Set the Current Working Directory inside the container
WORKDIR /primitive

# Copy everything from the current directory to the Working Directory inside the container
COPY . .

# Install the primitive package
RUN go install github.com/bclews/primitive@latest

# Stage 2: Create a lightweight image with the Go binary and Python script
FROM alpine:3.18

# Install Python and pip
RUN apk add --no-cache python3=3.11.8-r0 py3-pip=23.1.2-r0

# Copy the Go binary from the builder stage
COPY --from=build /go/bin/primitive /usr/bin/primitive

# Copy the requirements file into the Docker image
COPY requirements.txt /primitive/

# Install Python packages from the requirements file
RUN pip3 install --no-cache-dir -r /primitive/requirements.txt

# Copy your Python script into the Docker image (replace 'your_script.py' with the actual filename)
COPY service.py /primitive/

VOLUME /app
WORKDIR /app

# Run your Python script (replace 'your_script.py' with the actual filename)
ENTRYPOINT ["python", "/primitive/service.py"]
