# Introduction: IVCAP Queue Service
The IVCAP Queue endpoint (`/1/queues`) provides APIs for managing queues and performing queue operations like enqueuing and dequeuing messages. Queues are a fundamental component of an event-driven architecture, enabling decoupled communication between producers and consumers. With this endpoint, you can create new queues, list existing ones, retrieve queue details, delete queues, as well as send messages to a queue (enqueue) and retrieve messages from a queue (dequeue). The Queue endpoint supports to give you fine-grained control over queue management.

# Ocean Temperature Data Processing System

This project demonstrates a distributed system for processing environmental data, specifically ocean temperature measurements collected from various buoys. This simple example showcases a practical application of using the IVCAP Queue endpoint in distributed systems in the scientific domain.

## Overview

The system consists of two main components:

1. **Producer**: Simulates the collection of temperature data from buoys and publishes this data to the IVCAP Queue.
2. **Consumer**: Consumes the data from the IVCAP Queue, processes it, and logs the data.

## Components

### Producer

The producer script (`producer.py`) simulates the collection of temperature data from buoys. It generates random temperature readings and publishes them to a specified IVCAP Queue.

The producer accepts the following parameters:

- `number_of_data_points`: The number of data points (temperature readings) to publish to the queue.
- `queue_id`: The identifier of the IVCAP Queue to publish the data to.

### Consumer

The consumer script (`consumer.py`) retrieves and logs the temperature data from the specified IVCAP Queue.

The consumer accepts the following parameters:

- `subscription_duration`: The duration in minutes to consume data from the queue.
- `queue_id`: The identifier of the IVCAP Queue to consume data from.

The consumer continuously checks the queue for new data and logs any received temperature measurements until the specified subscription duration has elapsed.

## Getting Started

1. Set up your IVCAP environment and authenticate with the IVCAP CLI.
2. Create an IVCAP Queue using the IVCAP CLI or the IVCAP Console.
3. Build and publish the producer and consumer Docker images using the provided Makefiles.
4. Register the producer and consumer services with IVCAP using the `service-register` Make target.
5. Run the producer service with the appropriate parameters to publish synthetic temperature data to the queue.
6. Run the consumer service with the appropriate parameters to consume and log the temperature data from the queue.

Refer to the IVCAP documentation for more information on managing queues and running services.
