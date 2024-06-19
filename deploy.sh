#!/bin/sh
set -e

export ENV=$1
export NAME=$(jq -r .name package.json)
export VERSION=$(jq -r .version package.json)
export REGISTRY_NAMESPACE=$REGISTRY
export HASH=$(git rev-parse --short HEAD)

# DOCKER_HOST="ssh://docker-deploy@10.40.1.15:2222"
export IMAGE="$REGISTRY_NAMESPACE/$NAME:$VERSION"

# BUILD STEP (to review)
if [ -z "$SKIP_BUILD" ]; then

    DOCKER_BUILDKIT=1 docker build --tag "$NAME" --network=host .

    # Docker Hub push
    echo Pushing "$IMAGE" on "$ENV"
    docker tag "$NAME" "$IMAGE"
    docker push "$IMAGE"
    echo Deploying "$IMAGE" on "$ENV" with host "$DOCKER_HOST"
fi

if [ "$ENV" = "production" ]; then
    DOCKER_HOST="ssh://docker-deploy@$SWARM_HOST:2222"
fi

# Deploying
echo Deploying "$ENV" in the cluster with host "$DOCKER_HOST"

envsubst <kubernetes/${ENV}-deployment.yaml >manifest.yaml
envsubst <kubernetes/secrets.yaml >>secrets.yaml

# run the kubectl apply via ssh
ssh -p 2222 docker-deploy@156.54.237.240 'cat - | kubectl apply -f -' <secrets.yaml
ssh -p 2222 docker-deploy@156.54.237.240 'cat - | kubectl apply -f -' <manifest.yaml
