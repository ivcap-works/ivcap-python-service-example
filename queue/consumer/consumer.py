#
# Copyright (c) 2023 Commonwealth Scientific and Industrial Research Organisation (CSIRO). All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#
import logging
import time
from typing import Dict
from ivcap_sdk_service import (
    Service,
    Parameter,
    PythonWorkflow,
    Type,
    register_service,
    get_queue_service,
)

SERVICE = Service(
    name="Queue Consumer",
    description="A service that consumes synthetic buoy data from a queue.",
    parameters=[
        Parameter(
            name="subscription_duration",
            type=Type.INT,
            description="The duration in minutes to consume data from the queue.",
        ),
        Parameter(
            name="queue_id",
            type=Type.STRING,
            description="The identifier of the queue to consume data from.",
        ),
    ],
    workflow=PythonWorkflow(
        min_memory="2Gi", min_cpu="500m", min_ephemeral_storage="4Gi"
    ),
)


def consume_data(args: Dict, logger: logging):
    """
    Function to consume data from a queue.
    """
    # Get the queue service and retrieve the queue
    queue_service = get_queue_service()
    queue = queue_service.read(args.queue_id)
    if queue is None:
        raise ValueError(f"Queue with ID {args.queue_id} not found.")
    logger.info(f"Retrieved queue {queue['name']} with ID {args.queue_id}.")

    # Consume synthetic buoy data from the queue
    start_time = time.time()
    while time.time() - start_time < args.subscription_duration * 60:
        measurement = queue_service.dequeue(args.queue_id, limit=1)
        if measurement is None:
            logger.info("No data available in the queue. Waiting for data...")
            time.sleep(1)
            continue

        logger.info(f"Consumed data: {measurement}")


register_service(SERVICE, consume_data)
