# Quick reference

* Maintained by: [the Posit Docker team](https://github.com/rstudio/rstudio-docker-products)
* Where to get help: [our Github Issues page](https://github.com/rstudio/rstudio-docker-products/issues)
* Posit Connect image: [Docker Hub](https://hub.docker.com/r/rstudio/rstudio-connect)
* Posit Connect Content Init image: [Docker Hub](https://hub.docker.com/r/rstudio/rstudio-connect-content-init)

# Supported tags and respective Dockerfile links

* [`jammy`, `ubuntu2204`, `jammy-2024.12.0`, `ubuntu2204-2024.12.0`](https://github.com/rstudio/rstudio-docker-products/blob/main/connect/Dockerfile.2204)

# What is Posit Connect?

Posit Connect connects you and the work you do with others as never before. Only Posit Connect provides:

* "One button" deployment into a single environment for Shiny applications, R Markdown documents, Plumber APIs, 
  Python Jupyter notebooks, Quarto documents and projects, or any static R plot or graph.
* Extended deployment capabilities supporting Python APIs and applications using Shiny, Flask, Dash, FastAPI, Bokeh, 
  and Streamlit, as well as automated deployments for any content type via Git or command-line scripts.
* The ability to manage and limit access to the work you've shared with others - and easily see the work they've shared 
  with you.
* "Hands free" scheduling of updates to your documents and automatic email distribution.

For more information on running Posit Connect in your organization please visit 
https://posit.co/products/enterprise/connect/.

# Notice for support

1. This image may introduce **BREAKING** changes; as such we recommend:
   - Avoid using the `{operating-system}` tags to avoid unexpected version upgrades, and
   - Always read through the [NEWS](./NEWS.md) to understand the changes before updating.
1. Outdated images will be removed periodically from DockerHub as product version updates are made. Please make plans to
   update at times or use your own build of the images.
1. These images are meant as a starting point for your needs. Consider creating a fork of this repo, where you can
   continue to merge in changes we make while having your own security scanning, base OS in use, or other custom
   changes. We
   provide [instructions for building](https://github.com/rstudio/rstudio-docker-products#instructions-for-building) for
   these cases.
1. **Security Note:** These images are provided AS IS based on the build environment at the time their product version was released/updated. They should be reviewed and updated before production use. If your organization has a specific set of security requirements related to CVE/Vulnerability severity levels, you should plan to use the [instructions for building](https://github.com/rstudio/rstudio-docker-products#instructions-for-building) to clone this repository, and rebuild these images to your specific internal security standards.


# How to use this image

Below is a very simple example for running Connect locally in Docker.
```bash
# Replace with valid license
export RSC_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX

# Run without persistent data and using default configuration
docker run -it --privileged \
    -p 3939:3939 \
    -e RSC_LICENSE=$RSC_LICENSE \
    rstudio/rstudio-connect:ubuntu2204
```
Once running, open [http://localhost:3939](http://localhost:3939) to access RStudio Connect.

## Overview

This Docker container is built following
the [Posit Connect admin guide](https://docs.posit.co/connect/admin/index.html), please
see [Server Guide/Docker](https://docs.posit.co/connect/admin/server-management/#docker) for more details on the
requirements and how to extend this image.

This container includes:

1. Two versions of R
2. Two versions of Python
3. Posit Professional Drivers
4. Posit Connect

Note that running the Posit Connect Docker image requires the container to run using the `--privileged` flag and a
valid Posit Connect license.

> IMPORTANT: to use Posit Connect with more than one user, you will need to
> define `Server.Address` in the `rstudio-connect.gcfg` file. To do so, update
> your configuration file with the URL that users will use to visit Connect.
> Then start or restart the container.

## Configuration

The configuration of Posit Connect is made on the `/etc/rstudio-connect/rstudio-connect.gcfg` file, mount this file as
volume with an external file on the host machine to change the configuration and restart the container for changes to
take effect.

Be sure the config file has these fields:

- `Server.Address` set to the exact URL that users will use to visit Connect. A
  placeholder `http://localhost:3939` is in use by default
- `Server.DataDir` set to `/data/`
- `HTTP.Listen` (or equivalent `HTTP`, `HTTPS`, or `HTTPRedirect` settings. This could change how you should configure the container ports)
- `Python.Enabled` and `Python.Executable`

See a complete example of that file at `connect/rstudio-connect.gcfg`.

### Persistent Data

In order to persist Connect metadata and app data between container restarts configure the Connect `Server.DataDir` 
option to go to a persistent volume. 

The included configuration file expects a persistent volume from the host machine or your docker
orchestration system to be available at `/data`. Should you wish to move this to a different path, you can change the
`Server.DataDir` option.

### Licensing

Using the Posit Connect docker image requires to have a valid License. You can set the license in three ways:

1. Setting the `RSC_LICENSE` environment variable to a valid license key inside the container
2. Setting the `RSC_LICENSE_SERVER` environment variable to a valid license server / port inside the container
3. Mounting a `/etc/rstudio-connect/license.lic` single file that contains a valid license for Posit Connect

**NOTE:** the "offline activation process" is not supported by this image today. Offline installations will need
to explore using a license server, license file, or custom image with manual intervention.

### Environment variables

| Variable | Description | Default |
|-----|---|---|
| `RSC_LICENSE` | License key for Posit Connect, format should be: `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX` | None |
| `RSC_LICENSE_SERVER` | Floating license server, format should be: `my.url.com:port` | None |

### Ports

| Variable | Description |
|-----|---|
| `3939` | Default HTTP Port for Posit Connect |

### Example usage

```bash
# Replace with valid license
export RSC_LICENSE=XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX

# Run without persistent data and using an external configuration
docker run -it --privileged \
    -p 3939:3939 \
    -v $PWD/connect/rstudio-connect.gcfg:/etc/rstudio-connect/rstudio-connect.gcfg \
    -e RSC_LICENSE=$RSC_LICENSE \
    rstudio/rstudio-connect:ubuntu2204

# Run with persistent data and using an external configuration
docker run -it --privileged \
    -p 3939:3939 \
    -v $PWD/data/rsc:/data \
    -v $PWD/connect/rstudio-connect.gcfg:/etc/rstudio-connect/rstudio-connect.gcfg \
    -e RSC_LICENSE=$RSC_LICENSE \
    rstudio/rstudio-connect:ubuntu2204
```

Open [http://localhost:3939](http://localhost:3939) to access Posit Connect.

## Caveats of product licensing in containers

*Note: This section **does not** apply to activations using license files.*

There is currently a known licensing bug when using our products in containers. If the container is not stopped
gracefully, the license deactivation step may fail or be skipped. Failing to deactivate the license can result in a 
"license leak" where a product activation is used up and cannot be deactivated using traditional methods as the 
activation state on the container has been lost.

To avoid "leaking" licenses, we encourage users not to force kill containers and to use `--stop-timeout 120` and 
`--time 120` for `docker run` and `docker stop` commands respectively. This helps ensure the deactivation script has 
ample time to run properly.

In some situations, it can be difficult or impossible to avoid a hard termination (e.g. power failure, 
critical error on host). Unfortunately, any of these cases can still cause a license to leak an activation. To help
prevent a license leak in these situations, users can mount the following directories to persistent storage to preserve
the license state data across restarts of the container. **These directories differ between products.**

* License Key
  * `/var/lib/.local`
  * `/var/lib/.prof`
  * `/var/lib/rstudio-connect`
* Floating License
  * `/var/lib/.TurboFloat`

Please note that the files created in these directories are hardware locked and non-transferable between hosts. Due to
the nature of the hardware fingerprinting algorithm, any low-level changes to the host or container can cause existing
license state files to invalidate. To avoid this problem, we advise that product containers are gracefully shutdown
and allowed to deactivate prior to changing any hardware or firmware on the host (e.g. upgrading a network card or 
updating BIOS) or the container (e.g. changing the network driver used or the allocated number of CPU cores).

While preserving license state data *can* help avoid license leaks across restarts, it's not a guarantee. If you run
into issues with your license, please do not hesitate to [contact Posit support](https://support.posit.co/hc/en-us).

While neither of these solutions will eliminate the problem, they should help mitigate it. We are still investigating a 
long-term solution.

# Licensing
The license associated with the Posit Docker Products repository is located 
[in LICENSE.md](https://github.com/rstudio/rstudio-docker-products/blob/main/LICENSE.md).

As is the case with all container images, the images themselves also contain other software which may be under other
licenses (i.e. bash, linux, system libraries, etc., along with any other direct or indirect dependencies of the primary
software being contained).

It is an image user's responsibility to ensure that use of this image (and any of its dependent layers) complies with
all relevant licenses for the software contained in the image.
