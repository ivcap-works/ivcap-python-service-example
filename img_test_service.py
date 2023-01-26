from PIL import Image, ImageDraw, ImageFont

from ivcap_sdk_service import Service, Parameter, Option, Type, IOAdapter, IOWritable, SupportedMimeTypes
from ivcap_sdk_service import register_service, deliver_data, fetch_data, register_saver
import logging

from typing import Any, Dict

import os
import json

logger = None # set when called by SDK

SERVICE = Service(
    name = "simple-python-service",
    description = "A simple IVCAP service using the IVCAP Service SDK to create an image with text overlays",
    parameters = [
        Parameter(
            name='msg', 
            type=Type.STRING, 
            description='Message to display.'),
        Parameter(
            name='img-art', 
            type=Type.ARTIFACT, 
            description='Image artifact to use as background.',
            optional=True),
        Parameter(
            name='img-url', 
            type=Type.STRING, 
            description='Image url (external) to use as background.',
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

PNG_MT = 'image/png'

def service(args: Dict, svc_logger: logging):
    global logger 
    logger = svc_logger

    # Create an image
    img = Image.new("RGBA", (args.width, args.height), "white")
    
    # Add background
    if args.img_url:
        f = fetch_data(args.img_url)
        background = Image.open(f)
        img.paste(background)
        f.close() # the above code does not close the file
    
    # Draw message
    canvas = ImageDraw.Draw(img)
    font = ImageFont.truetype('CaveatBrush-Regular.ttf', 90)
    center = (args.width / 2, args.height / 2)
    canvas.text(center, args.msg, font=font, anchor='mm', fill=(255, 130, 0))   
    
    # deliver_data("image", lambda fd: img.save(fd, format="png"),
    #         PNG_MT, metadata={'msg': args.msg})
    metadata={
        '@type': '...',
        'msg': args.msg,
    }
    deliver_data("image", img, SupportedMimeTypes.JPEG, metadata=metadata)

# def png_saver(name: str, img: Any, io_adapter: IOAdapter, **kwargs):
#     print("IMG", str(type(img)))
#     fhdl: IOWritable = io_adapter.write_artifact(PNG_MT, f"{name}.png", **kwargs)
#     img.save(fhdl, format="png")
#     fhdl.close()
# register_saver(PNG_MT, None, png_saver)

register_service(SERVICE, service)
