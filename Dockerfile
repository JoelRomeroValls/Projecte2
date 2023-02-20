FROM orboan/dind
MAINTAINER Joel Romero y Yimi Ayala

LABEL version="1.0"
LABEL description="Asix - Projecte 2"

ARG language=ca_ES

ENV \
	USER=alumne \
	PASSWORD=alumne \
	LANG="${language}.UTF-8" \
	LC_CTYPE="${language}.UTF-8" \
	LC_ALL="${language}.UTF-8" \
	LANGUAGE="${language}:ca" \
	REMOVE_DASH_LINECOMMENT=true \
	SHELL=/bin/bash
ENV \
	HOME="/home/$USER" \
	DEBIAN_FRONTEND="noninteractive" \
	RESOURCES_PATH="/resources" \
	SSL_RESOURCES_PATH="/resources/ssl"
ENV \
	WORKSPACE_HOME="${HOME}" \
	MYSQL_ALLOW_EMPTY_PASSWORD=true \
	MYSQL_USER="$USER" \
	MYSQL_PASSWORD="$PASSWORD"

    
# Layer cleanup script
COPY clean-layer.sh  /usr/bin/
COPY fix-permissions.sh  /usr/bin/
RUN chmod +x /usr/bin/clean-layer.sh /usr/bin/fix-permissions.sh


# Make folders
RUN \
	mkdir -p $RESOURCES_PATH && chmod a+rwx $RESOURCES_PATH && \
	mkdir -p $SSL_RESOURCES_PATH && chmod a+rwx $SSL_RESOURCES_PATH && \
	mkdir -p /etc/scrips /etc/docker-compose  /var/lock/apache2 /var/run/apache2 /var/run/sshd /var/log/supervisor /var/logs /var/run/supervisor

## locales
RUN \
	if [ "$language" != "en_US" ]; then \
    	apt-get -y update; \
    	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales; \
    	echo "${language}.UTF-8 UTF-8" > /etc/locale.gen; \
    	locale-gen; \
    	dpkg-reconfigure --frontend=noninteractive locales; \
    	update-locale LANG="${language}.UTF-8"; \
	fi \
	&& clean-layer.sh

# install basics
RUN \
  apt update -y && \
  if ! which gpg; then \
    apt-get install -y --no-install-recommends gnupg; \
  fi; \
  clean-layer.sh
RUN \
  apt update -y && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  build-essential \
  software-properties-common \
  libcurl4 \
  curl \
  apt-utils \
  vim \    
  iputils-ping \
  ssh \
  fonts-dejavu \
  git \
  wget \
  openssl \
  libssl-dev \
  libgdbm-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libmysqlclient-dev \
  libpq-dev \
  bash-completion \
  zip \
  gzip \
  unzip \
  bzip2 \
  lzop \
  tzdata \
  sudo && \
  clean-layer.sh
 
RUN \
	apt update -y && \
	apt -y install supervisor openssh-server apache2 mariadb-server && \
	clean-layer.sh

# Instal·lem les dependències necessàries
RUN apt update -y && apt-get install -y \
	python3 \
	python3-pip \
	nodejs \
	npm \
	docker.io \
	docker-compose \
	mysql-client \
	git \
	maven \
	gradle

# Instala VS Code para la web
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
	install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/ && \
	sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' && \
	apt-get update && \
	apt-get install -y code

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
RUN chmod a+x "$HOME/.sdkman/bin/sdkman-init.sh"
RUN /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk version"

# Install Github CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt-get update && apt-get install -y gh


# Configurem SSH
RUN echo 'root:root' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# Permetre als usuaris connectar-se als serveis de mysql
#RUN usermod -aG docker $USER

#Entorno MYSQL
ENV MYSQL_ROOT_PASSWORD: root1234
ENV MYSQL_USER: dev
ENV MYSQL_PASSWORD: dev
ENV MYSQL_DATABASE: bbdduniversitat


#Copiamos archivos
COPY supervisord.conf  ///var/run/supervisor.sock
COPY supervisord.conf  /etc/supervisor/conf.d/*.conf
COPY universidad.sh /etc/scrips
COPY docker-compose.yml /etc/docker-compose

# Configurem Puertos
EXPOSE 8081 2222 3306 9001 443 80
