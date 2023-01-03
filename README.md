# IVCAP Demo Service 

## Usage

After registering the service, we need to package the model (see [README](export_model/README.md))
and upload it as well as upload the image to run the model against.
`ivcap artifact create` will be one of the tools to accomplish that.

Assuming we set the `SERVICE_ID` environment variables to the respective IVCAP idenifiers,
we can kick-off an analytics task with:

```
ivcap order create $SERVICE_ID --msg "Hi Sydney"
```

## Deployment

Build and publish the docker container implementing the Demo service. Before you start, please update the first few variables in [Makefile](./Makefile)

```
make docker-publish
```

Submit the service description to an IVCAP cluster. This assumes that the `ivcap-cli` tool is installed and the user is properly logged into the respective service account.

```
make service-register
```

Please note the service ID (e.g. `cayp:service:...`) as we will need that when 'ordering' an annotated image from this service.

## Development

The entire service is included in the `img_test_service.py` file. This file contains essentially three parts:

* SERVICE: Description of the serive and its paramters
* `def service(...`: The implementation of the service
* `register_service(SERVICE, service)`: The entry point combining the service description and its implementation.


Installing a development environment follows the usual conda environment pattern.

```
conda create --name ivcap_demo_service python=3.9 -y
conda activate ivcap_demo_service
pip install -r requirements.txt
```
