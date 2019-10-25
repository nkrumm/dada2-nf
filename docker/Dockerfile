FROM bioconductor/release_core2:R3.5.1_Bioc3.7

ARG DADA2_COMMIT
ENV DADA2_COMMIT=$DADA2_COMMIT

ADD install-dada2.R /tmp/
RUN /usr/local/bin/Rscript /tmp/install-dada2.R
RUN mkdir -p /app /fh /mnt /run/shm

