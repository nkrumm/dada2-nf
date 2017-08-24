# A Docker image providing dada2 (among other things)

This repository contains a Dockerfile for building a Docker image
inheriting from r-base with a specified release version of the dada2
package installed.

## Version numbering

Images are tagged using the format

```
release-<dada2-version>[<image-version>]
```

where ```dada2-version``` corresponds to a dada2 release, and
```image-version``` is a single lowercase letter indicating an
incremental change to the image for a given version of dada2. Some
examples: ```release-1.4.1```, ```release-1.4.1a```

## Triggering builds

The automated build on DockerHub seems not to be triggered by a push
as advertised. An image corresponding to a specified tag can be
triggered using an API as described under "Build Settings" --> "Build
Triggers"
(https://hub.docker.com/r/nghoffman/dada2/~/settings/automated-builds/)
