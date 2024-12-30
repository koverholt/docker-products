### Variable definitions ###
variable CONNECT_VERSION {
    default = "2024.12.0"
}

variable PACKAGE_MANAGER_VERSION {
    default = "2024.11.0-7"
}

variable WORKBENCH_VERSION {
    default = "2024.12.0+467.pro1"
}

variable DRIVERS_VERSION {
    default = "2024.03.0"
}

variable DEFAULT_QUARTO_VERSION {
    default = "1.4.557"
}

variable DEFAULT_JUPYTERLAB_VERSION {
    default = "3.6.7"
}

variable GIT_SHA {
    default = null
}

function tag_safe_version {
    params = [version]
    result = replace(version, "+", "-")
}

function clean_version {
    params = [version]
    result = regex_replace(version, "[+|-].*", "")
}

function get_drivers_version {
    params = [os]
    result = os == "centos7" ? "${DRIVERS_VERSION}-1" : DRIVERS_VERSION
}

function get_os_alt_name {
    params = [os]
    result = os == "ubuntu2204" ? "jammy" : os
}

function get_centos_tags {
    params = [os, product, product_version]
    # Bake automatically collapses any duplicate tags where clean versions and tag safe versions may be the same.
    result = [
        "ghcr.io/rstudio/${product}:${os}-${tag_safe_version(product_version)}",
        "ghcr.io/rstudio/${product}:${os}-${clean_version(product_version)}",
        "ghcr.io/rstudio/${product}:${os}-${clean_version(product_version)}--${GIT_SHA}",
        "ghcr.io/rstudio/${product}:${os}",
        "docker.io/rstudio/${product}:${os}-${tag_safe_version(product_version)}",
        "docker.io/rstudio/${product}:${os}-${clean_version(product_version)}",
        "docker.io/rstudio/${product}:${os}-${clean_version(product_version)}--${GIT_SHA}",
        "docker.io/rstudio/${product}:${os}",
    ]
}

function get_ubuntu_tags {
    params = [os, product, product_version]
    # Bake automatically collapses any duplicate tags where clean versions and tag safe versions may be the same.
    result = [
        "ghcr.io/rstudio/${product}:${os}-${tag_safe_version(product_version)}",
        "ghcr.io/rstudio/${product}:${os}-${clean_version(product_version)}",
        "ghcr.io/rstudio/${product}:${os}-${clean_version(product_version)}--${GIT_SHA}",
        "ghcr.io/rstudio/${product}:${get_os_alt_name(os)}-${tag_safe_version(product_version)}",
        "ghcr.io/rstudio/${product}:${get_os_alt_name(os)}-${clean_version(product_version)}",
        "ghcr.io/rstudio/${product}:${get_os_alt_name(os)}-${clean_version(product_version)}--${GIT_SHA}",
        "ghcr.io/rstudio/${product}:${get_os_alt_name(os)}",
        "ghcr.io/rstudio/${product}:${os}",
        "docker.io/rstudio/${product}:${get_os_alt_name(os)}-${tag_safe_version(product_version)}",
        "docker.io/rstudio/${product}:${get_os_alt_name(os)}-${clean_version(product_version)}",
        "docker.io/rstudio/${product}:${get_os_alt_name(os)}-${clean_version(product_version)}--${GIT_SHA}",
        "docker.io/rstudio/${product}:${os}-${tag_safe_version(product_version)}",
        "docker.io/rstudio/${product}:${os}-${clean_version(product_version)}",
        "docker.io/rstudio/${product}:${os}-${clean_version(product_version)}--${GIT_SHA}",
        "docker.io/rstudio/${product}:${get_os_alt_name(os)}",
        "docker.io/rstudio/${product}:${os}",
    ]
}

# FIXME: There's an obnoxious amount of hardcoding here due to restrictions with what bake can actually interpret from HCL.
function get_tags {
    params = [os, product, product_version]
    result = os == "ubuntu2204" ? get_ubuntu_tags(os, product, product_version) : get_centos_tags(os, product, product_version)
}

### Build matrices ###

variable BASE_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.11.10", py_alternate = "3.10.15"},
            {os = "ubuntu2204", r_primary = "4.4.0", r_alternate = "4.3.3", py_primary = "3.12.1", py_alternate = "3.11.7"},
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.12.6", py_alternate = "3.11.10"},
        ]
    }
}

variable PRO_BUILD_MATRIX {
    default = BASE_BUILD_MATRIX
}

variable PACKAGE_MANAGER_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.0", r_alternate = "4.3.3", py_primary = "3.12.1", py_alternate = "3.11.7"},
        ]
    }
}

variable CONNECT_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.0", r_alternate = "4.3.3", py_primary = "3.12.1", py_alternate = "3.11.7", quarto = DEFAULT_QUARTO_VERSION},
        ]
    }
}

variable CONNECT_CONTENT_INIT_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204"},
        ]
    }
}

variable CONTENT_BUILD_MATRIX {
  default = {
    # Add new entries to produce an image using a new patch version of
    # R/Python/Quarto. Do not modify existing entries, as that stops those
    # version combinations from receiving security updates.
    builds = [
      # R-3.6, Python-3.8, Quarto-1.3.
      {os = "ubuntu2204", os_alt = "jammy", r = "3.6.3", py = "3.8.16", drivers = "2024.03.0", quarto = "1.3.340"},
      {os = "ubuntu2204", os_alt = "jammy", r = "3.6.3", py = "3.8.19", drivers = "2024.03.0", quarto = "1.3.450"},

      # R-4.0, Python-3.9, Quarto-1.3.
      {os = "ubuntu2204", os_alt = "jammy", r = "4.0.5", py = "3.9.16", drivers = "2024.03.0", quarto = "1.3.340"},
      {os = "ubuntu2204", os_alt = "jammy", r = "4.0.5", py = "3.9.19", drivers = "2024.03.0", quarto = "1.3.450"},

      # R-4.1, Python-3.10, Quarto-1.3.
      {os = "ubuntu2204", os_alt = "jammy", r = "4.1.3", py = "3.10.11", drivers = "2024.03.0", quarto = "1.3.340"},
      {os = "ubuntu2204", os_alt = "jammy", r = "4.1.3", py = "3.10.14", drivers = "2024.03.0", quarto = "1.3.450"},

      # R-4.2, Python-3.11, Quarto-1.3.
      {os = "ubuntu2204", os_alt = "jammy", r = "4.2.2", py = "3.11.3", drivers = "2024.03.0", quarto = "1.3.340"},
      {os = "ubuntu2204", os_alt = "jammy", r = "4.2.3", py = "3.11.9", drivers = "2024.03.0", quarto = "1.3.450"},

      # R-4.3, Python-3.12, Quarto-1.4.
      {os = "ubuntu2204", os_alt = "jammy", r = "4.3.3", py = "3.12.3", drivers = "2024.03.0", quarto = "1.4.553"},

      # R-4.4, Python-3.12, Quarto-1.4.
      {os = "ubuntu2204", os_alt = "jammy", r = "4.4.0", py = "3.12.3", drivers = "2024.03.0", quarto = "1.4.553"},

      # R-4.4, Python-3.12.4, Quarto-1.4.557 (polyfill.js vulnerability patch)
      {os = "ubuntu2204", os_alt = "jammy", r = "4.4.1", py = "3.12.4", drivers = "2024.03.0", quarto = "1.4.557"},
    ]
  }
}

variable R_SESSION_COMPLETE_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.12.6", py_alternate = "3.11.10"},
        ]
    }
}

variable WORKBENCH_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.12.6", py_alternate = "3.11.10"},
        ]
    }
}

variable WORKBENCH_SESSION_MATRIX {
    default = PRO_BUILD_MATRIX
}

variable WORKBENCH_SESSION_INIT_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204"},
        ]
    }
}

variable WORKBENCH_GOOGLE_CLOUD_WORKSTATION_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.12.6", py_alternate = "3.11.10"},
        ]
    }
}

variable WORKBENCH_MICROSOFT_AZURE_ML_BUILD_MATRIX {
    default = {
        builds = [
            {os = "ubuntu2204", r_primary = "4.4.1", r_alternate = "4.3.3", py_primary = "3.11.10", py_alternate = "3.10.15"},
        ]
    }
}

### Group definitions ###
group "default" {
    targets = [
        "product-base",
        "product-base-pro",
        "connect",
        "connect-content-init",
        "content-base",
        "content-pro",
        "package-manager",
        "r-session-complete",
        "workbench",
        "workbench-session",
        "workbench-session-init",
    ]
}

group "base-images" {
    targets = [
        "product-base",
        "product-base-pro"
    ]
}

group "content-images" {
    targets = [
        "content-base",
        "content-pro"
    ]
}

### Base Image targets ###
target "base" {
    labels = {
        "maintainer" = "Posit Docker <docker@posit.co>"
    }
    output = ["type=image", "type=docker"]
}

target "product-base" {
    inherits = ["base"]
    target = "build"

    name = "product-base-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    tags = [
        "ghcr.io/rstudio/product-base:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
        "docker.io/rstudio/product-base:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
    ]

    dockerfile = "Dockerfile.${builds.os}"
    context = "product/base"

    matrix = BASE_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        TINI_VERSION = "0.19.0"
    }
}

target "product-base-pro" {
    inherits = ["base"]
    target = "build"

    name = "product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    tags = [
        "ghcr.io/rstudio/product-base-pro:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
        "docker.io/rstudio/product-base-pro:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
    ]

    dockerfile = "Dockerfile.${builds.os}"
    context = "product/pro"
    contexts = {
        product-base = "target:product-base-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = PRO_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        DRIVERS_VERSION = get_drivers_version(builds.os)
        TINI_VERSION = "0.19.0"
    }
}

### Package Manager targets ###
target "package-manager" {
    inherits = ["base"]
    target = "build"

    name = "package-manager-${builds.os}-${replace(PACKAGE_MANAGER_VERSION, ".", "-")}"
    tags = get_tags(builds.os, "rstudio-package-manager", PACKAGE_MANAGER_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "package-manager"
    contexts = {
        product-base = "target:product-base-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = PACKAGE_MANAGER_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        RSPM_VERSION = PACKAGE_MANAGER_VERSION
    }
}

### Connect targets ###
target "connect" {
    inherits = ["base"]
    target = "build"

    name = "connect-${builds.os}-${replace(CONNECT_VERSION, ".", "-")}"
    tags = get_tags(builds.os, "rstudio-connect", CONNECT_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "connect"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = CONNECT_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        RSC_VERSION = CONNECT_VERSION
        QUARTO_VERSION = builds.quarto
    }
}

target "connect-content-init" {
    inherits = ["base"]
    target = "build"

    name = "connect-content-init-${builds.os}-${replace(CONNECT_VERSION, ".", "-")}"
    tags = get_tags(builds.os, "rstudio-connect-content-init", CONNECT_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "connect-content-init"

    matrix = CONNECT_CONTENT_INIT_BUILD_MATRIX

    args = {
        RSC_VERSION = CONNECT_VERSION
    }
}

target "content-base" {
    inherits = ["base"]
    name = "content-base-r${replace(builds.r, ".", "-")}-py${replace(builds.py, ".", "-")}-${builds.os}"

    tags = [
        "ghcr.io/rstudio/content-base:r${builds.r}-py${builds.py}-${builds.os}",
        "ghcr.io/rstudio/content-base:r${builds.r}-py${builds.py}-${builds.os_alt}",
        "docker.io/rstudio/content-base:r${builds.r}-py${builds.py}-${builds.os}",
        "docker.io/rstudio/content-base:r${builds.r}-py${builds.py}-${builds.os_alt}",
        "ghcr.io/rstudio/content-base:r${builds.r}-py${builds.py}-quarto${builds.quarto}-${builds.os}",
        "ghcr.io/rstudio/content-base:r${builds.r}-py${builds.py}-quarto${builds.quarto}-${builds.os_alt}",
        "docker.io/rstudio/content-base:r${builds.r}-py${builds.py}-quarto${builds.quarto}-${builds.os}",
        "docker.io/rstudio/content-base:r${builds.r}-py${builds.py}-quarto${builds.quarto}-${builds.os_alt}",
    ]

    dockerfile = "Dockerfile.${builds.os}"
    context = "content/base"

    matrix = CONTENT_BUILD_MATRIX
    args = {
        R_VERSION = "${builds.r}"
        PYTHON_VERSION = "${builds.py}"
        QUARTO_VERSION = "${builds.quarto}"
    }
}

target "content-pro" {
    inherits = ["base"]
    name = "content-pro-r${replace(builds.r, ".", "-")}-py${replace(builds.py, ".", "-")}-${builds.os}"

    tags = [
        "ghcr.io/rstudio/content-pro:r${builds.r}-py${builds.py}-${builds.os}",
        "ghcr.io/rstudio/content-pro:r${builds.r}-py${builds.py}-${builds.os_alt}",
        "docker.io/rstudio/content-pro:r${builds.r}-py${builds.py}-${builds.os}",
        "docker.io/rstudio/content-pro:r${builds.r}-py${builds.py}-${builds.os_alt}",
    ]

    contexts = {
        content-base = "target:content-base-r${replace(builds.r, ".", "-")}-py${replace(builds.py, ".", "-")}-${builds.os}"
    }

    dockerfile = "Dockerfile.${builds.os}"
    context = "content/pro"

    matrix = CONTENT_BUILD_MATRIX
    args = {
        R_VERSION = "${builds.r}"
        DRIVERS_VERSION = "${builds.drivers}"
    }
}

### Workbench targets ###
target "r-session-complete" {
    inherits = ["base"]
    target = "build"

    name = "r-session-complete-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    tags = get_tags(builds.os, "r-session-complete", WORKBENCH_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "r-session-complete"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = R_SESSION_COMPLETE_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        JUPYTERLAB_VERSION = DEFAULT_JUPYTERLAB_VERSION
        RSW_VERSION = WORKBENCH_VERSION
        RSW_NAME = "rstudio-workbench"
        RSW_DOWNLOAD_URL = "https://download2.rstudio.org/server/jammy/amd64"
    }
}

target "workbench-session" {
    inherits = ["base"]
    name = "workbench-session-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"

    tags = [
        "ghcr.io/rstudio/workbench-session:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
        "docker.io/rstudio/workbench-session:${builds.os}-r${builds.r_primary}_${builds.r_alternate}-py${builds.py_primary}_${builds.py_alternate}",
    ]

    dockerfile = "Dockerfile.${builds.os}"
    context = "workbench-session"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }
    
    matrix = WORKBENCH_SESSION_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        JUPYTERLAB_VERSION = DEFAULT_JUPYTERLAB_VERSION
    }
}

target "workbench" {
    inherits = ["base"]

    name = "workbench-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    tags = get_tags(builds.os, "rstudio-workbench", WORKBENCH_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "workbench"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = WORKBENCH_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        PYTHON_VERSION_JUPYTER = builds.py_alternate
        RSW_VERSION = WORKBENCH_VERSION
        RSW_NAME = "rstudio-workbench"
        RSW_DOWNLOAD_URL = "https://download2.rstudio.org/server/jammy/amd64"
    }
}

target "workbench-session-init" {
    inherits = ["base"]
    target = "build"

    name = "workbench-session-init-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    tags = get_tags(builds.os, "workbench-session-init", WORKBENCH_VERSION)

    dockerfile = "Dockerfile.${builds.os}"
    context = "workbench-session-init"

    matrix = WORKBENCH_SESSION_INIT_BUILD_MATRIX

    args = {
        RSW_VERSION = WORKBENCH_VERSION
    }
}

### Workbench for Google Cloud Workstations targets ###
target "workbench-for-google-cloud-workstations" {
    inherits = ["base"]

    name = "workbench-for-google-cloud-workstation-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    tags = [
        "us-central1-docker.pkg.dev/posit-images/cloud-workstations/workbench:${tag_safe_version(WORKBENCH_VERSION)}",
        "us-central1-docker.pkg.dev/posit-images/cloud-workstations/workbench:latest",
        "europe-docker.pkg.dev/posit-images/cloud-workstations/workbench:${tag_safe_version(WORKBENCH_VERSION)}",
        "europe-docker.pkg.dev/posit-images/cloud-workstations/workbench:latest",
        "asia-docker.pkg.dev/posit-images/cloud-workstations/workbench:${tag_safe_version(WORKBENCH_VERSION)}",
        "asia-docker.pkg.dev/posit-images/cloud-workstations/workbench:latest",
        "us-docker.pkg.dev/posit-images/cloud-workstations/workbench:${tag_safe_version(WORKBENCH_VERSION)}",
        "us-docker.pkg.dev/posit-images/cloud-workstations/workbench:latest",
    ]

    dockerfile = "Dockerfile.${builds.os}"
    context = "workbench-for-google-cloud-workstations"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = WORKBENCH_GOOGLE_CLOUD_WORKSTATION_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        PYTHON_VERSION_JUPYTER = builds.py_alternate
        JUPYTERLAB_VERSION = DEFAULT_JUPYTERLAB_VERSION
        QUARTO_VERSION = DEFAULT_QUARTO_VERSION
        DRIVERS_VERSION = get_drivers_version(builds.os)
        RSW_VERSION = WORKBENCH_VERSION
        RSW_NAME = "rstudio-workbench"
        RSW_DOWNLOAD_URL = "https://download2.rstudio.org/server/jammy/amd64"
    }
}

### Workbench for Microsoft Azure ML targets ###
target "build-workbench-for-microsoft-azure-ml" {
    inherits = ["base"]
    target = "build"

    name = "build-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"

    dockerfile = "Dockerfile.${builds.os}"
    context = "workbench-for-microsoft-azure-ml"
    contexts = {
        product-base-pro = "target:product-base-pro-${builds.os}-r${replace(builds.r_primary, ".", "-")}_${replace(builds.r_alternate, ".", "-")}-py${replace(builds.py_primary, ".", "-")}_${replace(builds.py_alternate, ".", "-")}"
    }

    matrix = WORKBENCH_MICROSOFT_AZURE_ML_BUILD_MATRIX
    args = {
        R_VERSION = builds.r_primary
        R_VERSION_ALT = builds.r_alternate
        PYTHON_VERSION = builds.py_primary
        PYTHON_VERSION_ALT = builds.py_alternate
        PYTHON_VERSION_JUPYTER = builds.py_alternate
        JUPYTERLAB_VERSION = DEFAULT_JUPYTERLAB_VERSION
        RSW_VERSION = WORKBENCH_VERSION
        RSW_NAME = "rstudio-workbench"
        RSW_DOWNLOAD_URL = "https://download2.rstudio.org/server/jammy/amd64"
    }
}

target "scan-workbench-for-microsoft-azure-ml" {
    inherits = ["build-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"]
    target = "clamav"

    name = "scan-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"

    contexts = {
        build = "target:build-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    }

    matrix = WORKBENCH_MICROSOFT_AZURE_ML_BUILD_MATRIX
}

target "workbench-for-microsoft-azure-ml" {
    inherits = ["build-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"]
    target = "final"

    name = "workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    tags = get_tags(builds.os, "rstudio-workbench-for-microsoft-azure-ml", WORKBENCH_VERSION)

    contexts = {
        build = "target:build-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
        clamav = "target:scan-workbench-for-microsoft-azure-ml-${builds.os}-${replace(tag_safe_version(WORKBENCH_VERSION), ".", "-")}"
    }

    matrix = WORKBENCH_MICROSOFT_AZURE_ML_BUILD_MATRIX
}
