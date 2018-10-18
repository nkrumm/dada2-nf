FROM bioconductor/release_core2:R3.5.1_Bioc3.7

ADD setup.R /tmp/
RUN /usr/local/bin/Rscript /tmp/setup.R
RUN mkdir -p /app /fh /mnt /run/shm

