#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR}

usage() {
  echo "Usage: $0  [-s <source code directory>] [-b <branch>] [-n <kindest/node version>" 1>&2
  exit 1
}

while getopts :s:b:n:h OPT
do
  case $OPT in
    s) KIND_SRC=$OPTARG ;;
    b) KIND_BRANCH=$OPTARG ;;
    n) KINDEST_VERSION=$OPTARG ;;
    h) usage ;;
    \?) usage ;;
  esac
done

# Configs
GOPATH=${GOPATH:-"${HOME}/go"}
KIND_SRC=${KIND_SRC:-"${GOPATH}/src/github.com/kubernetes-sigs/kind/"}
KIND_BRANCH=${KIND_BRANCH:-"main"}
KINDEST_VERSION=${KINDEST_VERSION:-"v1.21.1@sha256:fae9a58f17f18f06aeac9772ca8b5ac680ebbed985e266f711d936e91d113bad"}

TAG_NAME=${TAG_NAME:-"kind-builder"}
LOG_LEVEL=${LOG_LEVEL:-"5"}

# Setup
TOOL_DIR="${DIR}/tools"
mkdir -p ${TOOL_DIR}
KIND_BIN="${TOOL_DIR}/kind-${KIND_BRANCH}"

# Checkout targeted kubernetes branch
cd ${KIND_SRC}
git fetch -t
git checkout -b ${KIND_BRANCH} ${KIND_BRANCH}

# Build container image for building kind
cd ${DIR}
docker build -t ${TAG_NAME} .

# Build kind in container
WORK_DIR="/tmp/workspace"
docker run --rm \
  -v ${KIND_SRC}:${WORK_DIR} \
  -w ${WORK_DIR} \
  ${TAG_NAME} \
  make build

cp -f ${KIND_SRC}/bin/kind ${KIND_BIN}

# Create symbolic link for kind
${DIR}/switch.sh kind ${KIND_BRANCH}
${DIR}/switch.sh kindest ${KINDEST_VERSION}

# Gather info
KIND_INFO="$(${KIND_BIN} version)"

# Reports
cat <<EOF

!!! kind was downloaded as ${KIND_BIN} !!!

kind info:
${KIND_INFO}"

EOF
