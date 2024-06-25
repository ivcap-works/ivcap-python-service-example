#
# Copyright (c) 2023 Commonwealth Scientific and Industrial Research Organisation (CSIRO). All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.
#
import logging
import subprocess

from pathlib import Path
from PIL import Image
from tempfile import TemporaryDirectory
from typing import List

from ivcap_sdk_service import (
    Parameter,
    PythonWorkflow,
    Service,
    ServiceArgs,
    SupportedMimeTypes,
    Type,
    publish_artifact,
    register_service,
)

logger = None  # set when called by SDK

SERVICE = Service(
    description="Reproduce images with geometric primitives.",
    name="primitive",
    parameters=[
        Parameter(
            name="input_image",
            description="input file",
            type=Type.ARTIFACT,
            optional=False,
        ),
        Parameter(
            name="n",
            description="number of shapes",
            type=Type.INT,
            default=100,
            optional=True,
        ),
        Parameter(
            name="m",
            description="mode: 0=combo, 1=triangle, 2=rect, 3=ellipse, 4=cirle, 5=rotatedrect, 6=beziers, 7=rotatedellipse, 8=polygon",
            type=Type.INT,
            default=1,
            optional=True,
        ),
        Parameter(
            name="rep",
            description="add N extra shapes each iteration with reduced search (mostly good for beziers)",
            type=Type.INT,
            default=0,
            optional=True,
        ),
        Parameter(
            name="nth",
            description="save every Nth frame (only when %d is in output path)",
            type=Type.INT,
            default=1,
            optional=True,
        ),
        Parameter(
            name="r",
            description="resize large input images to this size before processing",
            type=Type.INT,
            default=256,
            optional=True,
        ),
        Parameter(
            name="s",
            description="output image size",
            type=Type.INT,
            default=1024,
            optional=True,
        ),
        Parameter(
            name="a",
            description="color alpha (use 0 to let the algorithm choose alpha for each shape)",
            type=Type.INT,
            default=128,
            optional=True,
        ),
        Parameter(
            name="bg",
            description="starting background color (hex)",
            type=Type.STRING,
            default="avg",
            optional=True,
        ),
        Parameter(
            name="j",
            description="number of parallel workers (default uses all cores)",
            type=Type.INT,
            default=0,
            optional=True,
        ),
    ],
    workflow=PythonWorkflow(script="/primitive/service.py", min_memory="2Gi"),
)


def create_directories(tmpdir: Path) -> Path:
    """
    Creates input and output directories in the given temporary directory.

    Args:
        tmpdir (Path): The temporary directory in which to create the input and output directories.

    Returns:
        Tuple[Path, Path]: A tuple containing the paths to the input and output directories, respectively.
    """
    input_dir = tmpdir / "input"
    input_dir.mkdir()
    return input_dir


def save_input_image(input_dir: Path, input_image: Image.Image) -> Path:
    """
    Saves the input image to the specified directory.

    Args:
        input_dir (Path): The directory to save the input image to.
        input_image (Image): The input image to save.

    Returns:
        Path: The path to the saved input image.
    """
    input_image_path = input_dir / "input.jpg"
    input_image.save(input_image_path)
    return input_image_path


def generate_command(
    input_image_path: Path, output_image_path: Path, args: ServiceArgs
) -> List[str]:
    """
    Generates a command to run the primitive service on an input image.

    Args:
        input_image_path (Path): The path to the input image.
        output_image_path (Path): The path to save the output image.
        parameters (Dict[str, any]): A dictionary of parameters to the command.

    Returns:
        List[str]: A list of command line arguments to run the primitive service.
    """
    # Start with the basic command
    command = ["primitive", "-i", input_image_path, "-o", output_image_path]

    # Iterate through args and add them to the command
    for field_name, field_value in args._asdict().items():
        # ignore input (`input_image`) and output (`output_image`) parameters (already added to command)
        if field_name not in ["input_image", "output_image"]:
            command.append(f"-{field_name}")
            command.append(str(field_value))

    return command


def execute_command(command: List[str]) -> bytes:
    """
    Executes a command and returns the output as bytes.

    Args:
        command (List[str]): A list of strings representing the command to execute.

    Returns:
        bytes: The output of the command as bytes.
    """
    result = subprocess.run(command, stdout=subprocess.PIPE)
    return result.stdout


def service(args: ServiceArgs, svc_logger: logging.Logger):
    """
    Runs the primitive service with the given arguments.

    Args:
        args (ServiceArgs): The arguments for the service.
        svc_logger (logging): The logger for the service.

    Returns:
        None
    """
    global logger
    logger = svc_logger

    logger.info(f"Called with {args}")
    input_image = Image.open(args.input_image)

    with TemporaryDirectory() as tmpdir:
        logger.info(f"Using temporary directory {tmpdir}")
        input_dir = create_directories(Path(tmpdir))

        logger.info("Saving input image")
        input_image_path = save_input_image(input_dir, input_image)

        output_image_path = Path(
            f"{input_image_path.parent}/{input_image_path.stem}_output.jpg"
        )

        logger.info("Generating primitive command")
        command = generate_command(input_image_path, output_image_path, args)

        logger.info(f"Running command via subprocess: {command}")
        output_data = execute_command(command)

        logger.info(f"Primitive output: \n{output_data.decode()}")

        logger.info(f"Creating metadata {output_image_path}")

        logger.info(f"Publishing output image {output_image_path}")
        publish_artifact(
            f"{output_image_path}",
            lambda buffer: buffer.write(open(output_image_path, "rb").read()),
            SupportedMimeTypes.JPEG,
        )


register_service(SERVICE, service)
