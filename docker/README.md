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

## Triggering builds

The automated build on DockerHub seems not to be triggered by a push
as advertised. An image corresponding to a specified tag can be
triggered using an API as described under "Build Settings" --> "Build
Triggers"
(https://hub.docker.com/r/nghoffman/dada2/~/settings/automated-builds/)
