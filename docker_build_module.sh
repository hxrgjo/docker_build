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


if [ ! -d ./bin ]; then
    echo create bin dir
    mkdir  bin
else
    echo empty bin dir
    rm bin/*
fi

docker run -it --rm  \
    -v $BUILD_PATH:/$SERVICE_NAME \
    -v $NOWPWD/bin:/$SERVICE_NAME/bin \
    -w /$SERVICE_NAME \
    -e CGO_ENABLED=0 \
    -e GOOS=linux \
    -e GOARCH=amd64 \
    golang:$GOLANG_VERSION \
    go build -v -a -installsuffix cgo -ldflags "-X main.VERSION=$BUILD_TAG -X main.COMMIT=$GITCOMMIT -X main.BUILDTIME=$BUILDTIME" \
    -o $SERVICE_NAME .

# mv build and copoy config file
mv $BUILD_PATH/$SERVICE_NAME bin/

# Check build file is exists or not
if [ -f "bin/$SERVICE_NAME" ]; then
    echo "build $SERVICE_NAME success"
else
    echo "build $SERVICE_NAME failure"
    exit 1
fi

## Create Dockerfile
 echo \
"FROM scratch
MAINTAINER rayli
ADD ./bin/$SERVICE_NAME /
ENTRYPOINT [\"/$SERVICE_NAME\"]
CMD  version"  > Dockerfile

# Replace service name to lower case and under lline
SERVICE_NAME=$(echo "$SERVICE_NAME" | awk '{print tolower($0)}')
SERVICE_NAME=$(echo "$SERVICE_NAME" | sed s/-/_/g)

DOCKER_REGISTRY_HOST="asia.gcr.io"

DOCKER_IMAGE_NAME="$DOCKER_REGISTRY_HOST/tspv1-188510/$SERVICE_NAME:$BUILD_TAG"

# ## Build Image
docker build -t $DOCKER_IMAGE_NAME .

echo $DOCKER_IMAGE_NAME
# ## Push Image
 docker push $DOCKER_IMAGE_NAME


