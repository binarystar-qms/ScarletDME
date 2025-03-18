#!/bin/bash
set -ue
cd "../"
echo name $DOCKER_IMAGE
echo version $DOCKER_VERSION

echo releasing to docker registry [$DOCKER_REGISTRY]

docker build -f ./docker/Dockerfile -t $DOCKER_IMAGE:$DOCKER_VERSION . --progress=plain
docker tag $DOCKER_IMAGE:$DOCKER_VERSION $DOCKER_IMAGE:latest
docker tag $DOCKER_IMAGE:$DOCKER_VERSION $DOCKER_REGISTRY/$DOCKER_IMAGE:$DOCKER_VERSION
docker push $DOCKER_REGISTRY/$DOCKER_IMAGE:$DOCKER_VERSION
