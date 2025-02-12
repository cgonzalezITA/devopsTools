# Tips
## Run an image for testing 
```shell
IMAGE_NAMEVERSION=imagename:version
DNAME=dockerName
docker run --rm -it --name $DNAME $IMAGE_NAMEVERSION

# This command overrides the default entry point and allows you to enter into the container to analyze the image
docker run --rm -it --name $DNAME --entrypoint '/bin/sh' $IMAGE_NAMEVERSION -c  'while true; do sleep 60;echo '.'; done'

# Access the docker from a different terminal
docker exec -it $DNAME "/bin/sh"
```

### [Permission denied while trying to run a docker command](https://stackoverflow.com/questions/47854463/docker-got-permission-denied-while-trying-to-connect-to-the-docker-daemon-socke)
```shell
sudo usermod -a -G docker $USER
newgrp docker
```