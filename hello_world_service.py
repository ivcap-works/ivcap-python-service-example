from PIL import Image, ImageDraw, ImageFont
import logging
from pathlib import Path

from ivcap_sdk_service import Service, Parameter, Type, SupportedMimeTypes, ServiceArgs
from ivcap_sdk_service import register_service, publish_artifact, create_metadata

logger = None # set when called by SDK

FONT_FILE='CaveatBrush-Regular.ttf'

SERVICE = Service(
    name = "hello-world-python",
    description = "A simple IVCAP service using the IVCAP Service SDK to create an image with text overlays",
    parameters = [
        Parameter(
            name='msg',
            type=Type.STRING,
            description='Message to display.'),
        Parameter(
            name='background-img',
            type=Type.ARTIFACT,
            description='Image artifact to use as background.',
            optional=True),
        Parameter(
            name='width',
            type=Type.INT,
            description='Image width.',
            default=640),
        Parameter(
            name='height',
            type=Type.INT,
            description='Image height.',
            default=480),
    ]
)

def service(args: ServiceArgs, svc_logger: logging):
    """Called after the service has started and all paramters have been parsed and validated

    Args:
        args (ServiceArgs): A Dict where the key is one of the `Parameter` defined in the above `SERVICE`
        svc_logger (logging): Logger to use for reporting information on the progress of execution
    """
    global logger
    logger = svc_logger

    # Create an image
    img = Image.new("RGBA", (args.width, args.height), "white")

    # Add background
    if args.background_img:
        bg = Image.open(args.background_img)
        bg = bg.resize((args.width, args.height))
        img.paste(bg)

    # Draw message
    canvas = ImageDraw.Draw(img)
    ff = f"{Path(__file__).resolve().parent}/{FONT_FILE}"
    logger.info(f"Loading font file '{ff}'")
    font = ImageFont.truetype(ff, 90)
    center = (args.width / 2, 3 * args.height / 4)
    canvas.text(center, args.msg, font=font, anchor='mm', fill=(255, 130, 0))

    meta = create_metadata('urn:example:schema:simple-python-service', **args._asdict())
    publish_artifact("image.png", lambda fd: img.save(fd, format="png"), SupportedMimeTypes.JPEG, metadata=meta)

#####
# An example of how to register an artifact saver for a non-supported Mime-Type
# from typing import Any
# from ivcap_sdk_service import IOAdapter, IOWritable, register_saver

# PNG_MT = 'image/png'
# def png_saver(name: str, img: Any, io_adapter: IOAdapter, **kwargs):
#     fhdl: IOWritable = io_adapter.write_artifact(PNG_MT, f"{name}.png", **kwargs)
#     img.save(fhdl, format="png")
#     fhdl.close()
# register_saver(PNG_MT, None, png_saver)

####
# Entry point
register_service(SERVICE, service)
