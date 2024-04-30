import logging
import random
import time
from typing import Dict
import requests
from ivcap_sdk_service import (
    Service,
    Parameter,
    PythonWorkflow,
    Type,
    register_service,
    get_queue_service,
)

SERVICE = Service(
    name="Queue Producer",
    description="A service that publishes synthetic buoy data to a queue.",
    parameters=[
        Parameter(
            name="number_of_data_points",
            type=Type.INT,
            description="Number of data points to publish to the queue.",
        ),
        Parameter(
            name="queue_id",
            type=Type.STRING,
            description="The identifier of the queue to publish data to.",
        ),
    ],
    workflow=PythonWorkflow(
        min_memory="2Gi", min_cpu="500m", min_ephemeral_storage="4Gi"
    ),
)


def publish_data(args: Dict, logger: logging):
    """
    Function to publish data to a queue.
    """

    # Get the queue service and retrieve the queue
    queue_service = get_queue_service()
    queue = queue_service.read(args.queue_id)
    if queue is None:
        raise ValueError(f"Queue with ID {args.queue_id} not found.")
    logger.info(f"Retrieved queue '{queue['name']}' with ID {args.queue_id}.")

    # Publish synthetic buoy data to the queue based on the number of data points specified
    for _ in range(args.number_of_data_points):
        data = {
            "temperature": random.uniform(10, 25),
            "location": f"Buoy{random.randint(100, 200)}",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        response = queue_service.enqueue(args.queue_id, data)
        logger.info(f"Published data: {data} and received response: {response}")
        time.sleep(0.2)  # Simulate data publishing time
    logger.info(f"Added {args.number_of_data_points} tasks to the queue.")


register_service(SERVICE, publish_data)
