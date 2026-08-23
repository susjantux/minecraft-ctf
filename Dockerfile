FROM ubuntu:22.04

# Evita richieste interattive durante l'installazione
ENV DEBIAN_FRONTEND=noninteractive

# Installa le dipendenze di sistema (SSH, Cron, Python, utilità)
RUN apt-get update && apt-get install -y \
    openssh-server \
    cron \
    sudo \
    openssl \
    tar \
    python3 \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Configura SSH per l'accesso alla "End Dimension"
RUN mkdir /var/run/sshd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Imposta la cartella di lavoro
WORKDIR /opt/minecraft_ctf

# Copia i file del progetto
COPY . /opt/minecraft_ctf

# Rende eseguibile l'entrypoint
RUN chmod +x entrypoint.sh

# Espone la porta SSH standard (22)
EXPOSE 22

# Avvia l'ambiente tramite lo script di entrypoint
ENTRYPOINT ["./entrypoint.sh"]
