FROM archlinux/archlinux:base-devel

# update db and install base software
RUN pacman -Syu --noconfirm --quiet --needed \
        cronie \
        devtools \
        pacutils \
        pacman-contrib

COPY root/etc/skel /etc/skel

ENV LANG=C \
    PATH="/usr/local/bin:$PATH" \
    REPO_NAME="custom" \
    PACKAGE_REPO="" \
    DEBUG_ARCH_REPOS="0" \
    BUILD_PACKAGES_ON_START="0" \
    PACMAN_CACHE_SERVER="" \
    # Every 15 Minutes
    CRON_FETCH_PACKAGES="*/15 * * * *" \
    # Every hour on minute 3
    CRON_AUR_SYNC_UPDATE="3 * * * *" \
    # Every week on Monday at at 12:08
    CRON_PACCACHE_CLEAN="8 0 * * 1"

RUN \
    echo "setting up systemd machine id" \
    && systemd-machine-id-setup \
    && echo "setting up user" \
    && useradd build --system --home-dir /var/cache/build --create-home \
    && usermod -G users build \
    && usermod -g wheel build \
    && chown -R build:build /var/cache/build \
    && echo "%wheel ALL=(ALL) NOPASSWD: ALL" > \
              /etc/sudoers.d/wheel \
    && chmod 0440 /etc/sudoers.d/wheel

USER build

ADD --chown=build:build https://aur.archlinux.org/cgit/aur.git/snapshot/aurutils.tar.gz /tmp
RUN \
    cd /tmp \
    && echo "installing aurutils" \
    && tar xzf /tmp/aurutils.tar.gz \
    && cd aurutils \
    && makepkg --noconfirm --rmdeps -rsci \
    && cd .. \
    && rm -rf aurutils aurutils.tar.gz

USER root

ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64.tar.gz /tmp
RUN \
    echo "installing s6overlay" \
    && cd /tmp \
    && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / --exclude="./bin" \
    && tar xzf /tmp/s6-overlay-amd64.tar.gz -C /usr ./bin \
    && rm /tmp/s6-overlay-amd64.tar.gz

RUN \
    echo "cleaning pacman cache" \
    && paccache --keep 0 --remove \
    && echo "setting up extra pacman config" \
    && echo "Include = /etc/pacman.d/*.conf" >> /etc/pacman.conf

COPY root /
COPY bin/ /usr/local/bin/

VOLUME /config \
       /var/cache/pacman

ENTRYPOINT ["/init"]
