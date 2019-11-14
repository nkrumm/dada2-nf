# A Docker image providing dada2 (among other things)

This repository contains a Dockerfile for building a Docker image
inheriting from r-base with a specified release version of the dada2
package installed.

## Building

Create the Docker image locally like this:

```
./build.sh
```

An optional first argument can be used to specify the dada2 version.

## Version numbering

Images are tagged using the format

```
release-<dada2-version>-<repo-version>
```

where ```dada2-version``` corresponds to a dada2 release, and
```repo-version``` is the output of ``git describe --tags --dirty``.

## Publishing images

Images are hosted at https://quay.io/nhoffman/dada2-nf

To push the most recent image:

```
image=$(docker images dada2 --format "{{.Repository}}:{{.Tag}}" | head -n1)
docker run "$image" echo "$image"
image_id=$(docker ps -l | grep $tag | cut -d' ' -f1)
docker commit $image_id "quay.io/nhoffman/$image"
docker push "quay.io/nhoffman/$image"
```

