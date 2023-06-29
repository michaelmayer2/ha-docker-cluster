FROM ubuntu:22.04

ARG GOSU_VERSION=1.11
ARG R_VERSIONS="3.6.3 4.0.5 4.1.2"
ARG RSWB_VERSION
ARG PROXY


# Install and configure R and RStudio Workbench

COPY rstudio/create.R /tmp/create.R 

RUN apt-get update -y && \
	apt-get install -y gdebi-core curl wget && \ 
	IFS=" "; for R_VERSION in $R_VERSIONS ; \
	do \
		curl -O https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb && \
		gdebi -n r-${R_VERSION}_1_amd64.deb && \
		rm -f r-${R_VERSION}_1_amd64.deb && \
		/opt/R/$R_VERSION/bin/Rscript /tmp/create.R ;\
	done && \
	apt clean all && \
        rm -rf /var/cache/apt
RUN apt-get update -y && groupadd  -g 999 rstudio-server && \ 
   	useradd -g 999 -m -u 999 -s /bin/bash rstudio-server && \
        curl -O https://s3.amazonaws.com/rstudio-ide-build/server/jammy/amd64/rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
	gdebi -n rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
	rm -f rstudio-workbench-${RSWB_VERSION}-amd64.deb && \
    	apt clean all && \
    	rm -rf /var/cache/apt

COPY rstudio/launcher.conf /etc/rstudio/launcher.conf
COPY rstudio/rserver.conf /etc/rstudio/rserver.conf
COPY rstudio/database.conf /etc/rstudio/database.conf
RUN chmod 0600 /etc/rstudio/database.conf
COPY rstudio/load-balancer /etc/rstudio/load-balancer


## Configure launcher.* and secure-cookie-key

RUN apt-get update && apt-get install -y uuid && \
	apt clean all && \
	rm -rf /var/cache/apt

RUN echo `uuid` > /etc/rstudio/secure-cookie-key && \
	chown rstudio-server:rstudio-server \
		/etc/rstudio/secure-cookie-key && \
    chmod 0600 /etc/rstudio/secure-cookie-key

RUN openssl genpkey -algorithm RSA \
		-out /etc/rstudio/launcher.pem \
		-pkeyopt rsa_keygen_bits:2048 && \
	chown rstudio-server:rstudio-server \
		/etc/rstudio/launcher.pem && \
        chmod 0600 /etc/rstudio/launcher.pem

RUN openssl rsa -in /etc/rstudio/launcher.pem \
		-pubout > /etc/rstudio/launcher.pub && \
	chown rstudio-server:rstudio-server \
		/etc/rstudio/launcher.pub


## Add VSCode and Jupyter/Python 

### Install Python  -------------------------------------------------------------#

ARG PYTHON_VERSION=3.8.10
RUN curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION}_1_amd64.deb && \
    apt-get update && gdebi -n python-${PYTHON_VERSION}_1_amd64.deb && apt clean all && \
    rm -rf /var/cache/apt && rm -f python-${PYTHON_VERSION}_1_amd64.deb

RUN /opt/python/${PYTHON_VERSION}/bin/pip install --upgrade pip 

RUN /opt/python/${PYTHON_VERSION}/bin/pip install \
    jupyter \
    jupyterlab \
    workbench_jupyterlab \
    rsp_jupyter \
    rsconnect_jupyter \
    rsconnect_python 

RUN /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION}/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter
 

ARG PYTHON_VERSION_ALT=3.9.5
RUN curl -O https://cdn.rstudio.com/python/ubuntu-2204/pkgs/python-${PYTHON_VERSION_ALT}_1_amd64.deb && \
    apt-get update && gdebi -n python-${PYTHON_VERSION_ALT}_1_amd64.deb && apt clean all && \
    rm -rf /var/cache/apt && rm -f python-${PYTHON_VERSION_ALT}_1_amd64.deb

RUN /opt/python/${PYTHON_VERSION_ALT}/bin/pip install --upgrade pip

RUN /opt/python/${PYTHON_VERSION_ALT}/bin/pip install \
    jupyter \
    jupyterlab \
    workbench_jupyterlab \
    rsp_jupyter \
    rsconnect_jupyter \
    rsconnect_python 

RUN /opt/python/${PYTHON_VERSION_ALT}/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter && \
    /opt/python/${PYTHON_VERSION_ALT}/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter

COPY rstudio/jupyter.conf /etc/rstudio/jupyter.conf


#### Install VSCode code-server --------------------------------------------------#

#COPY rstudio/vscode.conf /etc/rstudio/vscode.conf
#COPY rstudio/vscode-user-settings.json  /etc/rstudio/vscode-user-settings.json
# Install VSCode based on the PWB version. 
RUN /bin/bash -c "if ( rstudio-server | grep configure-vs-code ); then rstudio-server configure-vs-code ; rstudio-server install-vs-code-ext; else rstudio-server install-vs-code /opt/code-server/; fi"

## Install gosu

RUN apt-get update && apt-get install -y  gnupg

RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true


## Add test user rstudio

RUN groupadd rstudio -g 2048 \
        && useradd -m rstudio -s /bin/bash -u 2048 -g 2048\
        && bash -c "echo -e \"rstudio\\nrstudio\" | passwd rstudio"


COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["rstudio"]
