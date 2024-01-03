#!/bin/bash

IMAGE_NAME="myjenkins-blueocean"
IMAGE_TAG="2.440.2-1"
NETWORK_NAME="jenkins"
CONTAINER_NAME="jenkins-blueocean"

# Check if the image exists locally
if ! docker images "$IMAGE_NAME:$IMAGE_TAG" | awk '{print $1":"$2}' | grep -q "$IMAGE_NAME:$IMAGE_TAG"; then
    echo "Image not found. Building..."
    docker build -t "$IMAGE_NAME:$IMAGE_TAG" .
else
    echo "Image already exists. Skipping build."
fi

# Check if the network exists
if ! docker network ls --format '{{.Name}}' | grep -q "^$NETWORK_NAME$"; then
    echo "Network not found. Creating..."
    docker network create "$NETWORK_NAME"
else
    echo "Network already exists. Skipping creation."
fi

# Check if the container exists and start or run
if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    # Container exists
    if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        # Container exists but not running, start it
        echo "Starting existing Jenkins container..."
        docker start "$CONTAINER_NAME"
    else
        # Container is already running
        echo "Jenkins container is already running."
    fi
else
    # Container does not exist, create and start it
    echo "Jenkins container does not exist. Creating and starting..."
    docker run --name "$CONTAINER_NAME" --restart=on-failure --detach \
      --network "$NETWORK_NAME" --env DOCKER_HOST=tcp://docker:2376 \
      --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
      --volume jenkins-data:/var/jenkins_home \
      --volume jenkins-docker-certs:/certs/client:ro \
      --publish 8080:8080 --publish 50000:50000 "$IMAGE_NAME:$IMAGE_TAG"
    #this command will print the initial password on the console
    docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
fi
