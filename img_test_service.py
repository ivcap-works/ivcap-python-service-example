from PIL import Image, ImageDraw, ImageFont

from ivcap_sdk_service import Service, Parameter, Option, Type, register_service, deliver, cache_file
import logging

from typing import Dict

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


def service(args: Dict, svc_logger: logging):
    global logger 
    logger = svc_logger

    # Create an image
    img = Image.new("RGB", (args.width, args.height), "white")
    
    # Add background
    if args.img_url:
        f = cache_file(args.img_url)
        background = Image.open(f)
        img.paste(background)
    
    # Draw message
    canvas = ImageDraw.Draw(img)
    font = ImageFont.truetype('CaveatBrush-Regular.ttf', 100)
    center = (args.width / 2, args.height / 2)
    canvas.text(center, args.msg, font=font, anchor='mm', fill=(255, 130, 0))   
    
    # Display edited image
    #img.show()
    
    deliver("image.png", lambda fd: img.save(fd, format="png"),
            type='image/png', msg=args.msg)
    
register_service(SERVICE, service)
