#!/bin/bash

image=$1              # e.g. robjahn/keptn-prepare-project-bash

if [ -z $image ]; then
  echo "ABORTING: Image is a required argument"
  exit 1
fi

echo "==============================================="
echo "build"
echo "==============================================="
docker build -t $image .
docker push $image

