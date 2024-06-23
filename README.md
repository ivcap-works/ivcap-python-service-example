# IVCAP Demo Service

This directory implements a simple IVCAP service which creates an image with
a customizable message as well as an optional background image, such as the following:

<div>
  <img src="./docs/image-with-bg.png" style="border: 1px solid" width=400/>
</div>

## Usage: User Perspective

We assume that the service has already been deployed. To check that, we can use the `ivcap` cli tool.

```
% ivcap service list --filter "name~='hello-world-python'"
+----+--------------------+--------------------------------+
| ID | NAME               | ACCOUNT                        |
+----+--------------------+--------------------------------+
| @1 | hello-world-python | urn:ivcap:account:45a06508-... |
+----+--------------------+--------------------------------+
....
```

To get more information on the service itself:

```
% ivcap service get @1

          ID  urn:ivcap:service:8e048dfc- (@1)
        Name  hello-world-python
 Description  A simple IVCAP service using the IVCAP Service SDK to create an image with text overlays
  Account ID  urn:ivcap:account:45a06508-...
  Parameters  ┌────────────────┬────────────────────────────────┬──────────┬─────────┬──────────┐
              │ NAME           │ DESCRIPTION                    │ TYPE     │ DEFAULT │ OPTIONAL │
              ├────────────────┼────────────────────────────────┼──────────┼─────────┼──────────┤
              │            msg │ Message to display.            │ string   │         │ false    │
              ├────────────────┼────────────────────────────────┼──────────┼─────────┼──────────┤
              │ background-img │ Image artifact to use as backg │ artifact │         │ true     │
              │                │ round.                         │          │         │          │
              ├────────────────┼────────────────────────────────┼──────────┼─────────┼──────────┤
              │          width │ Image width.                   │ int      │ 640     │ false    │
              ├────────────────┼────────────────────────────────┼──────────┼─────────┼──────────┤
              │         height │ Image height.                  │ int      │ 480     │ false    │
              └────────────────┴────────────────────────────────┴──────────┴─────────┴──────────┘
```

We can now _order_ an image by creating an _order_:

```
% ivcap order create -n "test image order #1" urn:ivcap:service:8e048dfc-... msg="Hello World"
Order 'urn:ivcap:order:503e98af-...' with status 'pending' submitted.
```

To check progress on this order:

```
% ivcap order get urn:ivcap:order:503e98af-...

         ID  urn:ivcap:order:503e98af-...
       Name  test image order #1
     Status  executing
    Ordered  4 minutes ago (26 May 23 09:58 AEST)
    Service  hello-world-python (@6)
    ...

```

Which should finally change to something like:

```
% ivcap order get urn:ivcap:order:503e98af-...

         ID  urn:ivcap:order:503e98af-...
       Name  test image order #1
     Status  succeeded
    Ordered  3 minutes ago (01 Jun 23 15:51 AEST)
    Service  simple-python-service (@5)
 Account ID  urn:ivcap:account:45a06508-...
 Parameters  ┌───────────────────────┐
             │    msg =  Hello World │
             │  width =  640         │
             │ height =  480         │
             └───────────────────────┘
   Products  ┌────┬───────────┬────────────┐
             │ @1 │ image.png │ image/jpeg │
             └────┴───────────┴────────────┘
    ...
```

The service produces a an image (`image.png`) as _product_. Let's check out the image:

```
% ivcap artifact get @3

         ID  urn:ivcap:artifact:95339aa8-...
       Name  image.png
     Status  ready
       Size  11 kB
  Mime-type  image/jpeg
 Account ID  urn:ivcap:account:45a06508-...
   Metadata  ┌────┬──────────────────────────────────────────┐
             │ @1 │ ???                                      │
             │ @2 │ urn:ivcap:schema:artifact-usedBy-order.1 │
             │ @3 │ urn:ivcap:schema:artifact.1              │
             └────┴──────────────────────────────────────────┘
```

To download the mage, use the artifact ID from the above _image.png_
(`ID  urn:ivcap:artifact:1ea046c7-...`):

```
% ivcap artifact download urn:ivcap:artifact:95339aa8-... -f /tmp/image.jpg
... downloading file 100% [==============================] (750 kB/s)
```

which may look like:

<div>
  <img src="./docs/image.jpg" style="border: 1px solid" width=400/>
</div>

To create a new image with a background image (please note the leading `urn:` on the image url):

```
% ivcap order create -n "test image order #2" urn:ivcap:service:266cf1ad-... \
  msg="Hello World" \
  background-img=urn:https://wallpaperaccess.com/full/4482737.png
Order 'urn:ivcap:order:663fa7e5-...' with status 'pending' submitted.
```

Following the above procedure to check on order progress, products (aka images) created and downloaded,
we should see something like:

<div>
  <img src="./docs/image-with-bg.png" style="border: 1px solid" width=400/>
</div>

## Build & Deployment

First, we need to setup a Python environment:

```
conda create --name ivcap_service python=3.8 -y
conda activate ivcap_service
pip install -r requirements.txt
```

To check if everything is properly installed, use the `run` target to execute the
service locally:

```
% make run
mkdir -p ./DATA
python img_test_service.py \
          --msg "05/06-12:13:40" \
                --background-img https://wallpaperaccess.com/full/4482737.png \
                --ivcap:out-dir /Users/ott030/src/IVCAP/Services/ivcap-python-service-example/DATA
INFO 2023-06-05T12:13:41+1000 ivcap IVCAP Service 'simple-python-service' ?/? (sdk 0.1.0/#?) built on ?.
INFO 2023-06-05T12:13:41+1000 ivcap Starting order 'None' for service 'simple-python-service' on node 'None'
INFO 2023-06-05T12:13:41+1000 ivcap Starting service with 'ServiceArgs(msg='05/06-12:13:40', background_img=<ReadableFile ...>, width=640, height=480)'
INFO 2023-06-05T12:13:41+1000 service Loading font file '/Users/ott030/src/IVCAP/Services/ivcap-python-service-example/CaveatBrush-Regular.ttf'
INFO 2023-06-05T12:13:41+1000 ivcap Written artifact 'image.png' to './DATA/image.png'
DEBUG 2023-06-05T12:13:41+1000 ivcap Notify {
  "name": "image.png",
  "artID": "file://./DATA/image.png",
  "mime_type": "image/jpeg",
  "meta": {
    "msg": "05/06-12:13:40",
    "background_img": "https://wallpaperaccess.com/full/4482737.png (cached)",
    "width": 640,
    "height": 480,
    "$schema": "urn:example:schema:simple-python-service"
  }
}
>>> Output should be in './DATA'
```

To build the docker container, publish it to the repository and register the service with the respective
IVCAP deploymewnt.

```
make docker-publish
```

Submit the service description to an IVCAP cluster. This assumes that the `ivcap-cli` tool is installed and the user is properly logged into the respective service account.

```
make service-register
```

Please note the service ID (e.g. `urn:ivcap:service:...`) as we will need that when ordering this service.

## Development

This service is implemented in `image_test_service.py` and consists of the following parts:

1. Service description
1. Service entry point
1. I/O
1. Service registration

### Service Description

The IVCAP SDK provides some convenience functions to describe the service and its parameters:

```python
from ivcap_sdk_service import Service, Parameter, Option, Type, ServiceArgs

SERVICE = Service(
    name = "simple-python-service",
    description = "A simple IVCAP service using the IVCAP Service SDK to create an image with text overlays",
    parameters = [
        Parameter(
            name='msg',
            type=Type.STRING,
            description='Message to display.'),
    ...
```

### Service Entrypoint

This function is called with a `Dict` containing all the service parameter settings according to the
above `SERVICE` declaration.

```python
def service(args: ServiceArgs, svc_logger: logging):
    """Called after the service has started and all paramters have been parsed and validated

    Args:
        args (ServiceArgs): A Dict where the key is one of the `Parameter` defined in the above `SERVICE`
        svc_logger (logging): Logger to use for reporting information on the progress of execution
    """
    ...
```

### I/O

One of the paramters is `background-img`, which is of type `artifact` and will therefore already been
_wrapped_ in an `IOReadable` instance which is a _file-like_ object and can often be directly provided
as argument to functions expecting such an instance:

```python
from PIL import Image

  ...
  # Add background
  if args.background_img:
      bg = Image.open(args.background_img)
```

To publish a result (aka _product_), we call the `deliver_data` function. Before we do that,
it is highly recommended to define _metadata_ further describing the result. the `create_metadata`
function is a convenience function to create a properly formatted metadata object. The first argument
is the schema to be used (`urn:example:schema:...`), followed by an arbitrary list of named values.

The first parameter to the `deliver_data` function is a name useful for debugging. The second on is
a lambda function called with a writable file descriptor to save the created image into
(`img.save(fd, format="png")`). The third paramter is the above described metadata descriptor.

```python
  meta = create_metadata('urn:example:schema:simple-python-service', **args._asdict())
  deliver_data("image.png", lambda fd: img.save(fd, format="png"), SupportedMimeTypes.JPEG, metadata=meta)
```

### Service registration

Finally, we need to register the `SERVICE` description and the `service(...)` entry function with IVCAP
providing the above describe `SERVICE` description as well as the `service` entry function.

```python
register_service(SERVICE, service)
```

### Testing & Troubleshooting

Please refer to the various `run...` targets in the [Makefile](Makefile)
