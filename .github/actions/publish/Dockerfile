FROM archlinux:latest

COPY publish.sh publish.sh

RUN yes | pacman -Syyu
RUN yes | pacman -S git github-cli

ENTRYPOINT ["/publish.sh"]
