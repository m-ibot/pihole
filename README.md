# Pi-hole Podman Deployment

This repository manages a Pi-hole instance deployed using Podman and podman-compose on Fedora.

## Tech Stack
- **Pihole**: Pihole, nework wide ad blocker: [home](https://pi-hole.net/), [docs](https://docs.pi-hole.net/), espically [docker docks](https://docs.pi-hole.net/docker/)
- **Image**: `pihole/pihole:latest` [docker hub](https://hub.docker.com/r/pihole/pihole)
- **Engine**: Podman [home](https://podman.io/), [docs](https://docs.podman.io/en/latest/)
- **Orchestration**: podman-compose [docs](https://docs.podman.io/en/latest/markdown/podman-compose.1.html)

[Google Gemini](https://gemini.google.com/) was used to discuss and solve problems during the setup of the pihole server. Furthermore [GeminiCLI](https://geminicli.com/) was used to update and structure the documentation.


## Usage

### Fedora specific setup & error fixes

Here are some issues I ran ito while trying to setting pihole up on Fedora 44.

First, try to start the container. If you run in any issue, come back to this section.

#### rootlessport cannot expose privileged port 53

Port 53 is the port used for DNS resolution and it is required to be used by pihole to actually work as a DNS server.

The Pihole documentation references to docker, but in this case we use podman instead. Docker and Podman are mostly comatible, but there is one difference between both of them: Podman runs rootless containers and has therefore less permissions on the host system This is actually a security advantage, but causes an error in this case.

If you run in this error, see the article ["Rootless podman is unable to use host ports less than 1024" in the RedHat knowledgebase](https://access.redhat.com/solutions/7044059)

To fix it, extend the file `/etc/sysctl.conf` by the following line:
 ```
 net.ipv4.ip_unprivileged_port_start=xxx
 ```

#### Disable DNS Resolver on Fedora host
When trying to start the container, the folloing error appeared:
`rootlessport listen tcp 0.0.0.0:53: bind: address already in use`

When executing `sudo netstat -pna | grep 53`, it showed that `systemd-resolve` was alredy listening on that port. Die output contained the following lines:
```
tcp  0  0  127.0.0.53:53  0.0.0.0:*  LISTEN  794/systemd-resolve
tcp  0  0  127.0.0.54:53  0.0.0.0:*  LISTEN  794/systemd-resolve
```

This error could be solved by adding `DNSStubListener=no` to the `[Resolve]` section of `/etc/systemd/resolved.conf`. If thge file was empty or did not exist efore, the result should look like that:
```
[Resolve]
DNSStubListener=no
```
Next, the symlink needs to be adjusted to point to the resolve file. Otherwise the host will lose it's internet conection bcause name resolution will not work anymore.
```
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```
Next, `systemd-resolved` needs to get restarted:
```
sudo systemctl restart systemd-resolved
```


### Starting and Stopping
- Start: `podman-compose up -d`
- Stop: `podman-compose down`

### Updating
Run the provided script to pull the latest image and restart the container:
```bash
./update-pihole.sh
```

### Security & Administration
The admin password is not stored in the configuration. To set or change it, execute:
```bash
podman exec -it pihole pihole setpassword
```
Explanation:
- `podman exec -it` opens an interactive shell in a container
- first `pihole` is the name of the container
- `pihole setpassword` is the command executed within the container. 

The password that is set here, can be used to ligin via the pihole WebUI 

### Healthcheck
The `docker-compose.yml` includes a healthcheck to ensure the DNS service is actually responding.

**How it works:**
Every 30 seconds, Podman runs the following command inside the container:
`dig +short +norecurse +retry=0 @127.0.0.1 localhost`

*   **`dig`**: A DNS lookup tool.
*   **`+short`**: Returns only the IP address to keep logs clean.
*   **`+norecurse`**: Ensures the check is purely local; it doesn't ask upstream servers on the internet.
*   **`+retry=0`**: Fails immediately if the first attempt doesn't work (Podman handles retries).
*   **`@127.0.0.1`**: Forces the query to the local Pi-hole service.
*   **`localhost`**: A standard domain that should always resolve to `127.0.0.1`.

**Timing Configuration:**
- **Interval (30s)**: How often the check runs.
- **Start Period (30s)**: A grace period during startup (to allow the gravity database to load) where failures are ignored.
- **Retries (3)**: The container is only marked "unhealthy" after 3 consecutive failures.

## Configuration Details

### Key Files
- `docker-compose.yml`: Defines the Pi-hole service. Note the use of `:Z` flags for SELinux compatibility.
- `resolv.conf`: Mounted into the container to provide reliable upstream DNS during the container's internal startup process, bypassing potential conflicts with the host's DNS configuration.

### Conventions & Quirks
- **Networking**: `FTLCONF_dns_listeningMode` is set to `ALL` to allow resolution from Docker's bridge network.
- **DNS Ports**: Port 53 (TCP/UDP) must be available on the host.
- **Volume Persistence**: Data is persisted in `./etc-pihole`.
