#!/bin/bash

# Check Args
if [ $# -lt 2 ]; then
    echo "Please Input Build Args : sh gbuild.sh {{build path}} {{tag}}"
    echo "Example : sh docker_build.sh \$HOME/go/src/gitlab.com/paganiniplus/TSPv2-API-Ad 1.0.2"
    exit 1
fi

BUILD_PATH=$1
BUILD_TAG=$2
NOWPWD=$(pwd)

## Check PATH
if [ ! -d $BUILD_PATH  ]; then
    echo "Error: Not find the Project\t"
    exit 1
fi

# Check Golang Image Version
GOLANG_VERSION="1.11.1"
echo Build Golang Version : $GOLANG_VERSION


# Get SERVICE_NAME
SERVICE_NAME=$(basename $BUILD_PATH)
GITCOMMIT=$(cd $BUILD_PATH && git rev-parse HEAD)
BUILDTIME=`date "+%Y/%m/%dT%H:%M:%S"`

cp -r $BUILD_PATH ./
cd $SERVICE_NAME

echo \
"FROM golang:1.11.1-alpine3.8 as build-env
# All these steps will be cached
RUN mkdir /$SERVICE_NAME
WORKDIR /$SERVICE_NAME
COPY go.mod .
COPY go.sum .

# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download
# COPY the source code as the last step
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -v -installsuffix cgo -o /go/bin/$SERVICE_NAME -ldflags \"-X main.VERSION=$BUILD_TAG -X main.COMMIT=$GITCOMMIT -X main.BUILDTIME=$BUILDTIME\"
FROM scratch
COPY --from=build-env /go/bin/$SERVICE_NAME /go/bin/$SERVICE_NAME
ENTRYPOINT [\"/go/bin/$SERVICE_NAME\"]" > Dockerfile

# Replace service name to lower case and under lline
SERVICE_NAME=$(echo "$SERVICE_NAME" | awk '{print tolower($0)}')
SERVICE_NAME=$(echo "$SERVICE_NAME" | sed s/-/_/g)

DOCKER_REGISTRY_HOST="asia.gcr.io"
DOCKER_IMAGE_NAME="$DOCKER_REGISTRY_HOST/tspv1-188510/$SERVICE_NAME:$BUILD_TAG"

## Build Image
docker build -t $DOCKER_IMAGE_NAME .

echo $DOCKER_IMAGE_NAME
## Push Image
docker push $DOCKER_IMAGE_NAME

# Delete copy folder
cd ..
rm -rf $(basename $BUILD_PATH)
