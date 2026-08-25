# Rootless Podman: point Docker-API clients at the user's podman socket.
if [ -n "${XDG_RUNTIME_DIR:-}" ] && [ -S "${XDG_RUNTIME_DIR}/podman/podman.sock" ]; then
    export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
fi

# podman-docker prints a "using podman instead of docker" notice on every
# invocation unless this file exists; silence it without touching /etc.
export PODMAN_COMPOSE_WARNING_LOGS=false
