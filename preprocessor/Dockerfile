FROM ubuntu:22.04

#https://neurostars.org/t/problems-installing-fsl/27620/30
RUN apt-get update --fix-missing
RUN apt-get -y install wget tar gzip build-essential
RUN apt-get -y install python3 libquadmath0 bc dc less libgl1-mesa-glx

RUN mkdir -p /home/localuser

RUN groupadd -g 1234 localgroup && \
    useradd -m -u 1234 -g localgroup localuser

# Install FSL 6.0.7.14

RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py
RUN chmod a+x fslinstaller.py
RUN python3 fslinstaller.py -s -d /usr/local/fsl -V 6.0.7.17 --conda

ENV FSLDIR=/usr/local/fsl
ENV PATH=$PATH:$FSLDIR/bin:$FSLDIR/share/fsl/bin

COPY .env /.env
COPY src/ /src
WORKDIR /src
RUN chmod +x *.sh

ENTRYPOINT ["/src/entrypoint.sh"]