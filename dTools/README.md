# Tips
## Run an image for testing 
```shell
docker run --rm -it --name test $IMAGE
```

## Other tips
- [Docker: Got permission denied while trying to connect to the Docker daemon](https://stackoverflow.com/questions/47854463/docker-got-permission-denied-while-trying-to-connect-to-the-docker-daemon-socke)
```shell
sudo usermod -a -G docker $USER
newgrp docker
```

- dCompose script uses the wrong "docker compose" command.
[Specify the DOCKERCOMPOSE_CMD env variable for your user](https://www.xda-developers.com/set-environment-variable-in-ubuntu/)