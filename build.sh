#!/bin/sh
git pull
HASH=$(git rev-parse --short HEAD)
docker build -t chrej/plantaid-server:latest -t chrej/plantaid-server:$HASH .
docker push -a chrej/plantaid-server
echo "Pushed image tag: $HASH"