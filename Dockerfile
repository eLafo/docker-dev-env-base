FROM ubuntu:16.04
MAINTAINER ASPgems

# Start by changing the apt otput, as stolen from Discourse's Dockerfiles.
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections &&\
# Probably a good idea
    apt-get update &&\

# Basic dev tools
    apt-get install -y sudo openssh-client git build-essential vim ctags man curl direnv software-properties-common locales bash-completion silversearcher-ag

# Install Homesick, through which dotfiles configurations will be installed
RUN apt-get install -y ruby &&\
    gem install homesick --no-rdoc --no-ri

# Install the Github Auth gem, which will be used to get SSH keys from GitHub
# to authorize users for SSH
RUN gem install github-auth --no-rdoc --no-ri

# Set up SSH. We set up SSH forwarding so that transactions like git pushes
# from the container happen magically.
RUN apt-get install -y openssh-server &&\
    mkdir /var/run/sshd &&\
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config

# Setting locale
RUN locale-gen es_ES.UTF-8 en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Config TERM
ENV TERM=xterm-256color

# Install tmux
RUN apt-get install -y libevent-dev libncurses-dev
RUN cd /tmp && wget https://github.com/tmux/tmux/releases/download/2.4/tmux-2.4.tar.gz 
RUN cd /tmp && tar -zxvf /tmp/tmux-2.4.tar.gz && cd /tmp/tmux-2.4 && ./configure && make && make install

RUN useradd dev -d /home/dev -m -s /bin/bash &&\
    adduser dev sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY ssh_key_adder.rb /home/dev/ssh_key_adder.rb
RUN chown dev:dev /home/dev/ssh_key_adder.rb &&\
    chmod +x /home/dev/ssh_key_adder.rb

USER dev
WORKDIR /home/dev

RUN \
# Set up The Editor of the Gods
    homesick clone https://github.com/eLafo/vim-dot-files.git &&\
    homesick symlink vim-dot-files &&\
    exec vim --not-a-term -c ":PluginInstall" -c "qall"

RUN \
    homesick clone eLafo/git-dot-files &&\
    homesick symlink git-dot-files

RUN \
    homesick clone eLafo/bash-dot-files &&\
    homesick symlink --force=true bash-dot-files

# Expose SSH
EXPOSE 22

VOLUME /home/dev/app
# Install the SSH keys of ENV-configured GitHub users before running the SSH
# server process. See README for SSH instructions.
CMD /home/dev/ssh_key_adder.rb && sudo /usr/sbin/sshd -D
