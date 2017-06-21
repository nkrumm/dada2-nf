FROM r-base:3.4.0

RUN apt-get update && \
apt-get install -y --no-install-recommends \
libcurl4-gnutls-dev \
libxml2-dev \
libssl-dev \
python \
&& \
useradd -r -s /sbin/nologin r-user

COPY setup.R /tmp/setup.R
RUN /usr/bin/Rscript /tmp/setup.R

# set user for container (must happen after R packages are installed)
USER r-user
