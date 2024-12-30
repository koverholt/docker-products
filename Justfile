#!/usr/bin/env just --justfile
set positional-arguments

vars := "-i ''"

sed_vars := if os() == "macos" { "-i ''" } else { "-i" }

BUILDX_PATH := ""

RSC_VERSION := "2024.12.0"
RSPM_VERSION := "2024.11.0-7"
RSW_VERSION := "2024.12.0+467.pro1"

DRIVERS_VERSION := "2023.05.0"
DRIVERS_VERSION_RHEL := DRIVERS_VERSION + "-1"

R_VERSION := "4.2.3"
R_VERSION_ALT := "4.1.3"

PYTHON_VERSION := "3.9.17"
PYTHON_VERSION_ALT := "3.8.17"
PYTHON_VERSION_RHEL := "3.9.14"
PYTHON_VERSION_ALT_RHEL := "3.8.15"

QUARTO_VERSION := "1.4.557"

SNYK_ORG := env("SNYK_ORG", "")

export RSC_LICENSE := ""
export RSPM_LICENSE := ""
export RSW_LICENSE := ""

# Targets for managing the buildx builder for Posit images

# just create-builder
create-builder:
  docker buildx create \
    --name posit-builder \
    --buildkitd-flags '--allow-insecure-entitlement security.insecure' \
    --buildkitd-config "{{justfile_directory()}}/share/local_buildkitd.toml"

# just delete-builder
delete-builder:
  docker buildx rm posit-builder

# Build and bake

# just build
alias build := bake
# just bake workbench-images
bake target="default":
  just -f {{justfile()}} create-builder || true
  GIT_SHA=$(git rev-parse --short HEAD) \
    docker buildx bake --builder=posit-builder -f docker-bake.hcl {{target}}

# just preview-bake workbench-images dev
alias preview-build := preview-bake
preview-bake target branch="$(git branch --show-current)":
  just -f {{justfile()}} create-builder || true
  WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local) \
  WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local) \
  PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local) \
  PACKAGE_MANAGER_PREVIEW_VERSION=$(just -f ci.Justfile get-version package-manager --type=preview --local) \
  CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local) \
  BRANCH="{{branch}}" \
    docker buildx bake --builder=posit-builder -f docker-bake.preview.hcl {{target}}

content-bake:
  just -f {{justfile()}} create-builder || true
  cd {{justfile_directory()}}/content && docker buildx bake --builder=posit-builder
  cd {{justfile_directory()}}

# just plan
plan:
  GIT_SHA=$(git rev-parse --short HEAD) \
    docker buildx bake -f docker-bake.hcl --print

# just preview-plan
preview-plan branch="$(git branch --show-current)":
  WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local) \
  WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local) \
  PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local) \
  CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local) \
  BRANCH="{{branch}}" \
    docker buildx bake -f docker-bake.preview.hcl --print

# Run tests

# just test workbench
test target="default" file="docker-bake.hcl":
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/test_bake_artifacts.py --target "{{target}}" --file "{{file}}"

# just preview-test connect dev
preview-test target="default" branch="$(git branch --show-current)":
  #!/bin/bash
  if [ -z "$WORKBENCH_DAILY_VERSION" ]; then
    WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local)
  fi
  if [ -z "$WORKBENCH_PREVIEW_VERSION" ]; then
    WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local)
  fi
  if [ -z "$PACKAGE_MANAGER_DAILY_VERSION" ]; then
    PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local)
  fi
  if [ -z "$CONNECT_DAILY_VERSION" ]; then
    CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local)
  fi
  if [ -z "$BRANCH" ]; then
    BRANCH="{{branch}}"
  fi
  WORKBENCH_DAILY_VERSION="${WORKBENCH_DAILY_VERSION}" \
  WORKBENCH_PREVIEW_VERSION="${WORKBENCH_PREVIEW_VERSION}" \
  PACKAGE_MANAGER_DAILY_VERSION="${PACKAGE_MANAGER_DAILY_VERSION}" \
  CONNECT_DAILY_VERSION="${CONNECT_DAILY_VERSION}" \
  BRANCH="${BRANCH}" \
  python3 {{justfile_directory()}}/tools/test_bake_artifacts.py --file docker-bake.preview.hcl --target "{{target}}"

# just snyk-code-test
snyk-code-test:
  snyk code test --org="{{SNYK_ORG}}" --sarif-file-output=code.sarif {{justfile_directory()}}

# just snyk-test workbench
snyk-test target="default" file="docker-bake.hcl" *opts="":
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "{{file}}" test {{opts}}

# just snyk-monitor workbench
snyk-monitor target="default" file="docker-bake.hcl" *opts="":
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "{{file}}" monitor {{opts}}

# just snyk-sbom workbench
snyk-sbom target="default" file="docker-bake.hcl" *opts="":
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "{{file}}" sbom {{opts}}

# just snyk-ignore workbench SNYK-XXXX-XXXX-XXXX "Reported upstream in <link>" 2024-08-31
snyk-ignore context snyk_id reason expiry:
  snyk ignore --id="{{snyk_id}}" --reason="{{reason}}" --expiry="{{expiry}}" --policy-path="{{context}}"

# just preview-snyk-test workbench
preview-snyk-test target="default" branch="$(git branch --show-current)" *opts="":
  WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local) \
  WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local) \
  PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local) \
  CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local) \
  BRANCH="{{branch}}" \
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "docker-bake.preview.hcl" test {{opts}}

# just snyk-monitor workbench
preview-snyk-monitor target="default" branch="$(git branch --show-current)" *opts="":
  WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local) \
  WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local) \
  PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local) \
  CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local) \
  BRANCH="{{branch}}" \
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "docker-bake.preview.hcl" monitor {{opts}}

# just snyk-sbom workbench
preview-snyk-sbom target="default" branch="$(git branch --show-current)" *opts="":
  WORKBENCH_DAILY_VERSION=$(just -f ci.Justfile get-version workbench --type=daily --local) \
  WORKBENCH_PREVIEW_VERSION=$(just -f ci.Justfile get-version workbench --type=preview --local) \
  PACKAGE_MANAGER_DAILY_VERSION=$(just -f ci.Justfile get-version package-manager --type=daily --local) \
  CONNECT_DAILY_VERSION=$(just -f ci.Justfile get-version connect --type=daily --local) \
  BRANCH="{{branch}}" \
  SNYK_ORG="{{SNYK_ORG}}" \
  GIT_SHA=$(git rev-parse --short HEAD) \
    python3 {{justfile_directory()}}/tools/snyk_bake_artifacts.py --target "{{target}}" --file "docker-bake.preview.hcl" sbom {{opts}}

# just lint workbench ubuntu2204
lint $PRODUCT $OS:
  #!/usr/bin/env bash
  docker run --rm -i -v $PWD/hadolint.yaml:/.config/hadolint.yaml ghcr.io/hadolint/hadolint < $PRODUCT/Dockerfile.$(just _parse-os {{OS}})

# Run targets

run product tag="":
  #!/bin/bash
  RSC_VERSION="ubuntu2204"
  RSW_VERSION="ubuntu2204"
  RSPM_VERSION="ubuntu2204"
  if [ "{{product}}" = "workbench" ] && [ -z "{{tag}}" ]; then
    RSW_VERSION="{{tag}}"
  elif [ "{{product}}" = "connect" ] && [ -z "{{tag}}" ]; then
    RSC_VERSION="{{tag}}"
  elif [ "{{product}}" = "package-manager" ] && [ -z "{{tag}}" ]; then
    RSPM_VERSION="{{tag}}"
  fi
  RSW_VERSION="${RSW_VERSION}" RSC_VERSION="${RSC_VERSION}" RSPM_VERSION="${RSPM_VERSION}" \
    docker compose up \
    --no-build \
    {{product}}

# Export/import targets

export-artifacts target build_definition="docker-bake.hcl":
  python3 {{justfile_directory()}}/tools/export_bake_artifacts.py --target "{{target}}" --file "{{build_definition}}"

import-artifacts:
  python3 {{justfile_directory()}}/tools/import_bake_artifacts.py

# Helper targets

# just _get-tag-safe-version 2022.07.2+576.pro12
_get-tag-safe-version $VERSION:
  #!/usr/bin/env bash
  echo -n "$VERSION" | sed 's/+/-/g'

# just _get-clean-version 2022.07.2+576.pro12
_get-clean-version $VERSION:
  #!/usr/bin/env bash
  echo -n "$VERSION" | sed 's/[+|-].*//g'

# just _parse-os jammy
_parse-os OS:
  #!/usr/bin/env bash
  if [[ "{{OS}}" == "bionic" ]]; then
    echo "ubuntu1804"
  elif [[ "{{OS}}" == "jammy" ]]; then
    echo "ubuntu2204"
  else
    echo "{{OS}}"
  fi

# just _rev-parse-os ubuntu2204
_rev-parse-os OS:
  #!/usr/bin/env bash
  if [[ "{{OS}}" == "ubuntu1804" ]]; then
    echo "bionic"
  elif [[ "{{OS}}" == "ubuntu2204" ]]; then
    echo "jammy"
  else
    echo "{{OS}}"
  fi

# just
_config-license-persist-volumes TYPE PRODUCT HOST_DIR:
  #!/usr/bin/env bash
  if [ "{{PRODUCT}}" = "package-manager" ]; then
    licensing_state_root_dir="/home/rstudio-pm"
    product_dir_name=".rstudio-pm"
  elif [ "{{PRODUCT}}" = "workbench" ]; then
    licensing_state_root_dir="/var/lib"
    product_dir_name="rstudio-workbench"
  elif [ "{{PRODUCT}}" = "connect" ]; then
    licensing_state_root_dir="/var/lib"
    product_dir_name="rstudio-connect"
  fi

  if [ "{{TYPE}}" = "key" ]; then
    mkdir -p {{HOST_DIR}}/local
    mkdir -p {{HOST_DIR}}/prof
    mkdir -p {{HOST_DIR}}/product

    echo "-v {{HOST_DIR}}/local:${licensing_state_root_dir}/.local -v {{HOST_DIR}}/prof:${licensing_state_root_dir}/.prof -v {{HOST_DIR}}/product:${licensing_state_root_dir}/${product_dir_name}"
  elif [ "{{TYPE}}" = "float" ]; then
    mkdir -p {{HOST_DIR}}/float

    echo "-v {{HOST_DIR}}/float:${licensing_state_root_dir}/.TurboFloat"
  fi

# Version and dependency version management

# just RSW_VERSION=1.2.3 R_VERSION=4.1.0 update-versions
update-versions:
  just \
    RSW_VERSION={{RSW_VERSION}} \
    RSC_VERSION={{RSC_VERSION}} \
    RSPM_VERSION={{RSPM_VERSION}} \
    R_VERSION={{R_VERSION}} \
    R_VERSION_ALT={{R_VERSION_ALT}} \
    PYTHON_VERSION={{PYTHON_VERSION}} \
    PYTHON_VERSION_ALT={{PYTHON_VERSION_ALT}} \
    PYTHON_VERSION_RHEL={{PYTHON_VERSION_RHEL}} \
    PYTHON_VERSION_ALT_RHEL={{PYTHON_VERSION_ALT_RHEL}} \
    DRIVERS_VERSION={{DRIVERS_VERSION}} \
    QUARTO_VERSION={{QUARTO_VERSION}} \
    update-rsw-versions update-rspm-versions update-rsc-versions update-r-versions update-py-versions update-drivers-versions update-quarto-versions

# just RSW_VERSION=1.2.3 update-rsw-versions
update-rsw-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  sed {{ sed_vars }} "s/RSW_VERSION=.*/RSW_VERSION={{ RSW_VERSION }}/g" \
    workbench/.env \
    r-session-complete/.env \
    workbench-for-microsoft-azure-ml/.env \
    r-session-complete/Dockerfile.ubuntu2204 \
    workbench/Dockerfile.ubuntu2204 \
    workbench-for-microsoft-azure-ml/Dockerfile.ubuntu2204 \
    workbench-session-init/Dockerfile.ubuntu2204
  sed {{ sed_vars }} "s/RSW_VERSION:.*/RSW_VERSION: {{ RSW_VERSION }}/g" docker-compose.yml
  sed {{ sed_vars }} "s/rstudio\/rstudio-workbench:.*/rstudio\/rstudio-workbench:$(just _get-clean-version {{ RSW_VERSION }})/g" docker-compose.yml
  sed {{ sed_vars }} "s/^RSW_VERSION := .*/RSW_VERSION := \"{{ RSW_VERSION }}\"/g" \
    Justfile
  sed {{ sed_vars }} "s/[0-9]\{4\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}/`just _get-clean-version {{ RSW_VERSION }}`/g" \
    workbench/README.md \
    r-session-complete/README.md \
    workbench-session-init/README.md
  awk -v new_version="{{ RSW_VERSION }}" '
  /variable WORKBENCH_VERSION/ { print; getline; print "    default = \"" new_version "\""; next }
  { print }
  ' docker-bake.hcl > file.tmp && mv file.tmp docker-bake.hcl

# just RSPM_VERSION=1.2.3 update-rspm-versions
update-rspm-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  sed {{ sed_vars }} "s/RSPM_VERSION=.*/RSPM_VERSION={{ RSPM_VERSION }}/g" \
    package-manager/.env \
    package-manager/Dockerfile.ubuntu2204
  sed {{ sed_vars }} "s/RSPM_VERSION:.*/RSPM_VERSION: {{ RSPM_VERSION }}/g" docker-compose.yml
  sed {{ sed_vars }} "s/rstudio\/rstudio-package-manager:.*/rstudio\/rstudio-package-manager:$(just _get-clean-version {{ RSPM_VERSION }})/g" docker-compose.yml
  sed {{ sed_vars }} "s/^RSPM_VERSION := .*/RSPM_VERSION := \"{{ RSPM_VERSION }}\"/g" \
    package-manager/Justfile \
    Justfile
  sed {{ sed_vars }} -E "s/[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}/`just _get-clean-version {{ RSPM_VERSION }}`/g" package-manager/README.md
  awk -v new_version="{{ RSPM_VERSION }}" '
  /variable PACKAGE_MANAGER_VERSION/ { print; getline; print "    default = \"" new_version "\""; next }
  { print }
  ' docker-bake.hcl > file.tmp && mv file.tmp docker-bake.hcl

# just RSC_VERSION=1.2.3 update-rsc-versions
update-rsc-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  sed {{ sed_vars }} "s/RSC_VERSION=.*/RSC_VERSION={{ RSC_VERSION }}/g" \
    connect/.env \
    connect/Dockerfile.ubuntu2204 \
    connect-content-init/Dockerfile.ubuntu2204
  sed {{ sed_vars }} "s/^RSC_VERSION := .*/RSC_VERSION := \"{{ RSC_VERSION }}\"/g" \
    Justfile
  sed {{ sed_vars }} -E "s/[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}/`just _get-clean-version {{ RSC_VERSION }}`/g" \
    connect/README.md \
    connect-content-init/README.md
  awk -v new_version="{{ RSC_VERSION }}" '
  /variable CONNECT_VERSION/ { print; getline; print "    default = \"" new_version "\""; next }
  { print }
  ' docker-bake.hcl > file.tmp && mv file.tmp docker-bake.hcl

# just R_VERSION=3.2.1 R_VERSION_ALT=4.1.0 update-r-versions
update-r-versions: update-default-r-versions
update-default-r-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  # Update primary R versions
  sed {{ sed_vars }} "s/R_VERSION=.*/R_VERSION={{ R_VERSION }}/g" \
    workbench/.env \
    connect/.env \
    package-manager/.env \
    package-manager/Dockerfile.ubuntu* \
    workbench/Dockerfile.ubuntu2204 \
    connect/Dockerfile.ubuntu2204 \
    product/base/Dockerfile.ubuntu* \
    product/pro/Dockerfile.ubuntu*
  sed {{ sed_vars }} "s/^R_VERSION := .*/R_VERSION := \"{{ R_VERSION }}\"/g" \
    workbench/Justfile \
    workbench-for-microsoft-azure-ml/Justfile \
    connect/Justfile \
    package-manager/Justfile \
    product/base/Justfile \
    product/pro/Justfile \
    Justfile \
    ci.Justfile

  # Update alt R versions
  sed {{ sed_vars }} "s/R_VERSION_ALT=.*/R_VERSION_ALT={{ R_VERSION_ALT }}/g" \
    workbench/.env \
    connect/.env \
    package-manager/.env \
    package-manager/Dockerfile.ubuntu* \
    workbench/Dockerfile.ubuntu2204 \
    connect/Dockerfile.ubuntu2204 \
    product/base/Dockerfile.ubuntu* \
    product/pro/Dockerfile.ubuntu*
  sed {{ sed_vars }} "s/^R_VERSION_ALT := .*/R_VERSION_ALT := \"{{ R_VERSION_ALT }}\"/g" \
    workbench/Justfile \
    workbench-for-microsoft-azure-ml/Justfile \
    connect/Justfile \
    package-manager/Justfile \
    product/base/Justfile \
    product/pro/Justfile \
    Justfile \
    ci.Justfile

# just PYTHON_VERSION=3.9.5 PYTHON_VERSION_ALT=3.8.10 update-py-versions
update-py-versions: update-default-py-versions
update-default-py-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  # Update primary Python versions
  sed {{ sed_vars }} "s/PYTHON_VERSION=.*/PYTHON_VERSION={{ PYTHON_VERSION }}/g" \
    workbench/Dockerfile.ubuntu2204 \
    workbench/.env \
    connect/Dockerfile.ubuntu2204 \
    connect/.env \
    package-manager/Dockerfile.ubuntu* \
    package-manager/.env \
    product/base/Dockerfile.ubuntu* \
    product/pro/Dockerfile.ubuntu* \
    r-session-complete/Dockerfile.ubuntu2204
  sed {{ sed_vars }} "s/PYTHON_VERSION=.*/PYTHON_VERSION={{ PYTHON_VERSION_RHEL }}/g" \
    product/base/Dockerfile.centos7 \
    product/pro/Dockerfile.centos7 \
    r-session-complete/Dockerfile.centos7
  sed {{ sed_vars }} "s/^PYTHON_VERSION := .*/PYTHON_VERSION := \"{{ PYTHON_VERSION }}\"/g" \
    workbench/Justfile \
    workbench-for-microsoft-azure-ml/Justfile \
    connect/Justfile \
    package-manager/Justfile \
    product/base/Justfile \
    product/pro/Justfile \
    Justfile \
    ci.Justfile

  # Update alt Python versions
  sed {{ sed_vars }} "s/PYTHON_VERSION_ALT=.*/PYTHON_VERSION_ALT={{ PYTHON_VERSION_ALT }}/g" \
    workbench/Dockerfile.ubuntu2204 \
    workbench/.env \
    connect/Dockerfile.ubuntu2204 \
    connect/.env \
    product/base/Dockerfile.ubuntu* \
    product/pro/Dockerfile.ubuntu* \
    r-session-complete/Dockerfile.ubuntu2204
  sed {{ sed_vars }} "s/PYTHON_VERSION_ALT=.*/PYTHON_VERSION_ALT={{ PYTHON_VERSION_ALT_RHEL }}/g" \
    product/base/Dockerfile.centos7 \
    product/pro/Dockerfile.centos7 \
    r-session-complete/Dockerfile.centos7
  sed {{ sed_vars }} "s/^PYTHON_VERSION_ALT := .*/PYTHON_VERSION_ALT := \"{{ PYTHON_VERSION_ALT }}\"/g" \
    workbench/Justfile \
    workbench-for-microsoft-azure-ml/Justfile \
    connect/Justfile \
    package-manager/Justfile \
    product/base/Justfile \
    product/pro/Justfile \
    Justfile \
    ci.Justfile

# just DRIVERS_VERSION=2022.11.0 update-driver-versions
update-drivers-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  sed {{ sed_vars }} "s/\"drivers\": \".[^\,\}]*\"/\"drivers\": \"{{ DRIVERS_VERSION }}\"/g" content/matrix.json
  sed {{ sed_vars }} "s/DRIVERS_VERSION=.*/DRIVERS_VERSION={{ DRIVERS_VERSION }}/g" \
    workbench-for-microsoft-azure-ml/Dockerfile.ubuntu2204 \
    content/pro/Dockerfile.ubuntu* \
    r-session-complete/Dockerfile.ubuntu* \
    product/pro/Dockerfile.ubuntu*
  sed {{ sed_vars }} "s/DRIVERS_VERSION=.*/DRIVERS_VERSION={{ DRIVERS_VERSION_RHEL }}/g" \
    r-session-complete/.env \
    r-session-complete/Dockerfile.centos7 \
    product/pro/Dockerfile.centos7
  sed {{ sed_vars }} "s/^DRIVERS_VERSION := .*/DRIVERS_VERSION := \"{{ DRIVERS_VERSION }}\"/g" \
    content/pro/Justfile \
    r-session-complete/Justfile \
    product/pro/Justfile \
    ci.Justfile
  sed -i '/variable DRIVERS_VERSION/!b;n;c\ \ \ \ default = "{{ RSC_VERSION }}"' docker-bake.hcl

update-quarto-versions:
  #!/usr/bin/env bash
  set -euxo pipefail
  sed {{ sed_vars }} "s/^QUARTO_VERSION := .*/QUARTO_VERSION := \"{{ QUARTO_VERSION }}\"/g" \
    content/base/Justfile \
    product/base/Justfile \
    ci.Justfile \
    Justfile
  sed {{ sed_vars }} "s/^QUARTO_VERSION=.*/QUARTO_VERSION={{ QUARTO_VERSION }}/g" \
    content/base/Dockerfile* \
    product/base/Dockerfile*
  sed {{ sed_vars }} "s/^Executable = \/opt\/quarto\/.*\/bin\/quarto/Executable = \/opt\/quarto\/{{ QUARTO_VERSION }}\/bin\/quarto/g" \
    connect/rstudio-connect.gcfg
  sed {{ sed_vars }} "s/qver=\${QUARTO_VERSION:-.*}/qver=\${QUARTO_VERSION:-{{ QUARTO_VERSION }}}/g" \
    content/base/maybe_install_quarto.sh
  sed -i '/variable DEFAULT_QUARTO_VERSION/!b;n;c\ \ \ \ default = "{{ QUARTO_VERSION }}"' docker-bake.hcl
