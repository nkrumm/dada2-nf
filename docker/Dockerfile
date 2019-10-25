FROM bioconductor/release_core2:R3.5.1_Bioc3.7

ARG DADA2_COMMIT
ENV DADA2_COMMIT=$DADA2_COMMIT

ADD install-dada2.R /tmp/
RUN /usr/local/bin/Rscript /tmp/install-dada2.R
RUN mkdir -p /app /fh /mnt /run/shm

RUN apt-get update -y --fix-missing && apt-get install -y python3-pip
RUN pip3 install barcodecop==0.4.1 openpyxl

ADD install_infernal_and_easel.sh /tmp/
RUN /tmp/install_infernal_and_easel.sh
