# docker

## gtrace

first you must run `xhost +local:docker` on your host.
after that, make sure you have this in your docker stack declaration:

    environment:
      DISPLAY: ":0.0"
    volumes:
      - "/tmp/.X11-unix:/tmp/.X11-unix:rw"

you should be good to go.

doing the same without docker-stack:
    http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/


