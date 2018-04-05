#!/bin/bash

set -e          # exit on command errors
set -o nounset  # abort on unbound variable
set -o pipefail # capture fail exit codes in piped commands
# set -x          # execution tracing debug messages

trap stop_docker EXIT

stop_docker() {
  echo "Terminating dockerd"
  local pid
  pid=$(pgrep dockerd)

  if [ -z "$pid" ]; then
    return 0
  fi

  kill -TERM "$pid"
  wait "$pid"
}

load_containers() {
  while read -r image; do
    # Load image
    docker load -i "${image}/image"
    # Tag image
    docker tag \
      "$(cat "${image}/image-id")" \
      "$(cat "${image}/repository"):$(cat "${image}/tag")"
  done < <(find /images/* -type d)
}

# Check storage (currently only overlay2)
rootfs=$(grep " / " /proc/mounts)
case "$rootfs" in
  *"overlay2"*)
    driver="overlay2"
    ;;
  *)
    # Default for dind image
    driver="vfs"
    ;;
esac

# Set dind fixes and start dockerd
dind dockerd \
  --host=unix:///var/run/docker.sock \
	--host=tcp://0.0.0.0:2375 \
  --storage-driver="$driver" >/tmp/docker.log 2>&1 &

load_containers

docker images

exec sh -exc "$@"
