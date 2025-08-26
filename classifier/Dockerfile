FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates unzip wget tar gzip
# install openjdk 11
RUN apt-get -y install openjdk-11-jdk
RUN apt-get -y install python3

# install weka 3.8.6
RUN wget https://prdownloads.sourceforge.net/weka/weka-3-8-6.zip -O /weka.zip
RUN unzip /weka.zip -d /weka
ENV WEKA_DIR=/weka/weka-3-8-6
ENV WEKA_JAR_PATH=$WEKA_DIR/weka.jar
RUN rm /weka.zip

# install weka packages
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package discriminantAnalysis
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package classificationViaClustering
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package LibLINEAR
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package RBFNetwork
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package netlibNativeLinux
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package functionalTrees
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package ForestPA
RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -install-package SysFor

RUN java -cp $WEKA_JAR_PATH weka.core.WekaPackageManager -list-packages installed

# install uv https://docs.astral.sh/uv/guides/integration/docker/#installing-uv
ADD https://astral.sh/uv/0.6.6/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"

RUN java --version

WORKDIR /app
# Copy the project into the image
COPY .env           .
COPY uv.lock        .
COPY pyproject.toml .
COPY src/           /app/src

# Sync the project into a new environment, using the frozen lockfile
RUN uv sync --frozen

WORKDIR /app/src
RUN chmod +x *.sh

ENTRYPOINT [ "/app/src/entrypoint.sh" ]