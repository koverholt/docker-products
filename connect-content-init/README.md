**PRE-RELEASE - DO NOT USE**

# Quick reference

* Maintained by: [the Posit Docker team](https://github.com/rstudio/rstudio-docker-products)
* Where to get help: [our Github Issues page](https://github.com/rstudio/rstudio-docker-products/issues)
* RStudio Connect image: [Docker Hub](https://hub.docker.com/r/rstudio/rstudio-connect)
* RStudio Connect Content Init image: [Docker Hub](https://hub.docker.com/r/rstudio/rstudio-connect-content-init)

# Supported tags and respective Dockerfile links

* [`jammy`, `ubuntu2204`, `jammy-2024.12.0`, `ubuntu2204-2024.12.0`](https://github.com/rstudio/rstudio-docker-products/blob/main/connect/Dockerfile.2204)

# RStudio Connect Content Init Container

This directory contains a Dockerfile and script that will create a "copy
container" to copy runtime components from a release package into a target
mount directory. This container can be used as an "init container" to pull the
runtime components into another image, which can then be used with Connect and
Launcher to build/run content.

## Building

Just will build an image using a default Connect distribution.

```console
just build
```

The version of the release package to use can be overridden with the
`RSC_VERSION` build arg.

```console
just build ubuntu2204 2024.12.0
```

## Testing

You can observe what gets copied by the container:

```console
mkdir rstudio-connect-runtime
docker run --rm -v $(pwd)/rstudio-connect-runtime:/mnt/rstudio-connect-runtime rstudio/rstudio-connect-content-init-preview:1.8.8.3-dev236
# The rstudio-connect-runtime directory has been populated with the Connect
# runtime components.
```

You can also test using goss:
```console
just test
```


## Inspection

You can see the different layers that make up the image:

```console
docker history rstudio/rstudio-connect-content-init-preview:2024.12.0-dev-326
```

NOTE: almost all the image size is pandoc.

# Licensing

The license associated with the RStudio Docker Products repository is located [in LICENSE.md](https://github.com/rstudio/rstudio-docker-products/blob/main/LICENSE.md).

As is the case with all container images, the images themselves also contain other software which may be under other
licenses (i.e. bash, linux, system libraries, etc., along with any other direct or indirect dependencies of the primary
software being contained).

It is an image user's responsibility to ensure that use of this image (and any of its dependent layers) complies with
all relevant licenses for the software contained in the image.
