# Agent Instructions

This file contains behavioral guidelines and constraints for AI agents working in this repository.

## Documentation Priority
1. Always read `README.md` first for project overview and operational procedures.
2. This `AGENTS.md` file contains only supplemental instructions for agents.

## Behavioral Guidelines
- **Tooling**: Use `podman-compose` commands. While aliases for `docker-compose` may exist on the host, explicit usage of `podman-compose` is preferred for clarity and consistency.
- **Updates**: ALWAYS use the `./update-pihole.sh` script for updating the image. Do not perform manual `podman pull` and restarts unless troubleshooting the script itself.

## Constraints
- **Secrets**: Never commit or log API keys or passwords. The `FTLCONF_webserver_api_password` setting in `docker-compose.yml` is intentionally commented out; do not uncomment it with a real password.
- **Volumes**: Be aware of the `:Z` SELinux flag on volumes. If adding new volumes, ensure they include the appropriate labeling flag for the host OS (Fedora).
