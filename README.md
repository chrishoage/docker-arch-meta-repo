# Docker Arch Meta Repo

This container is uses an Arch base to build meta packages that have AUR depends
using aurutils.

While offering some customization, this is for my own personal use. You probably shouldn't use it, especially if you're not familiar with Arch / AUR.

### Environment variables

- `DEBUG_ARCH_REPOS` `0` / `1` controls extra logging
- `BUILD_PACKAGES_ON_START` `0` / `1` forces a build when container starts
- `REPO_NAME` the name of the custom repo. Default is `custom`
- `PACKAGE_REPO` *Required* git path to meta packages
- `PACMAN_CACHE_SERVER` Local mirror cache like flexo
- `CRON_FETCH_PACKAGES` Interval to fetch meta packages. Defaults to 15 minutes
- `CRON_AUR_SYNC_UPDATE` Interval to update AUR packages. Defaults to every hours
- `CRON_PACCACHE_CLEAN` Interval to clear pacman cache. Defaults to once a week on Monday at 8am container time
- `TZ` Set the timezone of the contianer
- PUID User ID to use for build user and /config
- PGID Group ID to use for build group /config

### Docker Compose

```yml
version: '3.1'
services:
  pkgs:
    container_name: pkgs
    build: '.'
    tmpfs:
      - /run/systemd
    volumes:
      - ./config:/config
      - pkgcache:/var/cache/pacman
      - builddir:/var/lib/aurbuild
      - "/sys/fs/cgroup:/sys/fs/cgroup:ro"
    environment:
      - DEBUG_ARCH_REPOS=0
      - BUILD_PACKAGES_ON_START=1
      - REPO_NAME=custom-pkgs
      - PACKAGE_REPO=git@github.com:username/meta-pkg-repo.git
      - TZ=${TZ-America/Los_Angeles}
      - PUID=1000
      - PGID=1000
    cap_add:
      - SYS_ADMIN

volumes:
  builddir:
  pkgcache:

```

### Privileged container

This container uses aurutils chroot for builds, which in turn uses systemd-nspawn. In order for this to work correctly the following must be provided:

- A tempfs volume of `/run/systemd`
- A read only bind mount of `/sys/fs/cgroup:/sys/fs/cgroup`
- Either `privileged: true` or `SYS_ADMIN`

