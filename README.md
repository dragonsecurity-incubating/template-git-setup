# Forgejo Setup with Docker Compose

A complete Docker Compose setup for running [Forgejo](https://forgejo.org/) (a self-hosted Git service) with Caddy as a reverse proxy, PostgreSQL database, and automated CI/CD runners.

## Overview

This setup includes:
- **Forgejo**: Self-hosted Git service (similar to GitHub/GitLab)
- **PostgreSQL**: Database backend
- **Caddy**: Automatic HTTPS reverse proxy
- **2 CI/CD Runners**: Docker-in-Docker runners for running workflows

## Prerequisites

- Docker Engine (20.10+)
- Docker Compose (2.0+)
- A domain name pointing to your server (for SSL certificates)
- Ports 80, 443 (HTTP/HTTPS), and 2222 (SSH) available

## Quick Start

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
```

### 2. Clone the Repository

```bash
git clone https://github.com/dragonsecurity-incubating/template-git-setup.git
cd template-git-setup
```

### 3. Configure Your Domain

Edit the `docker-compose.yml` file and replace `git.example.com` with your actual domain:

```yaml
FORGEJO__server__DOMAIN: your-domain.com
FORGEJO__server__ROOT_URL: https://your-domain.com/
FORGEJO__server__SSH_DOMAIN: your-domain.com
```

Also update the `Caddyfile`:

```
your-domain.com {
    encode zstd gzip
    reverse_proxy forgejo:3000
}
```

### 4. Set Database Password

Change the default PostgreSQL password in `docker-compose.yml`:

```yaml
POSTGRES_PASSWORD: your_secure_password_here
# Also update in the Forgejo section:
FORGEJO__database__PASSWD: your_secure_password_here
```

### 5. Create Required Directories

Run the setup script to create directories with proper permissions:

```bash
./setup-directories.sh
```

Or manually:

```bash
mkdir -p runners/runner1 runners/runner2
sudo chown -R 1001:1001 runners/
chmod -R 755 runners/
```

### 6. Start the Services

```bash
docker compose up -d
```

Wait for all services to start (about 30 seconds). Check status:

```bash
docker compose ps
```

### 7. Initial Forgejo Configuration

Visit your domain (e.g., `https://your-domain.com`) and complete the initial setup:

1. Database settings should already be configured via environment variables
2. Create your administrator account
3. Configure any additional settings as needed

### 8. Register the Runners

After Forgejo is running, register the runners to enable CI/CD:

```bash
./register-runner.sh runner1
./register-runner.sh runner2
```

Or manually for each runner:

```bash
# Get a runner registration token from Forgejo:
# Go to: https://your-domain.com/admin/actions/runners
# Click "Create new Runner" and copy the registration token

# Register runner1
docker compose exec runner1 forgejo-runner register \
  --instance https://your-domain.com \
  --token YOUR_REGISTRATION_TOKEN \
  --name runner1 \
  --labels docker:docker://node:20,ubuntu-latest:docker://catthehacker/ubuntu:act-latest

# Register runner2
docker compose exec runner2 forgejo-runner register \
  --instance https://your-domain.com \
  --token YOUR_REGISTRATION_TOKEN \
  --name runner2 \
  --labels docker:docker://node:20,ubuntu-latest:docker://catthehacker/ubuntu:act-latest

# Restart runners to apply configuration
docker compose restart runner1 runner2
```

## Directory Structure

```
template-git-setup/
├── docker-compose.yml      # Main Docker Compose configuration
├── Caddyfile              # Caddy reverse proxy configuration
├── setup-directories.sh   # Script to create required directories
├── register-runner.sh     # Script to register runners
├── start.sh               # Convenience script to start everything
├── runners/
│   ├── runner1/           # Runner 1 configuration and data
│   │   └── config.yml     # Created after registration
│   └── runner2/           # Runner 2 configuration and data
│       └── config.yml     # Created after registration
└── README.md              # This file
```

## Management

### Start All Services

```bash
docker compose up -d
# Or use the convenience script:
./start.sh
```

### Stop All Services

```bash
docker compose down
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f forgejo
docker compose logs -f runner1
```

### Update Services

```bash
docker compose pull
docker compose up -d
```

### Backup

Important data locations:
- **Forgejo data**: Docker volume `forgejo_data`
- **PostgreSQL data**: Docker volume `postgres_data`
- **Runner configs**: `./runners/runner1/` and `./runners/runner2/`

```bash
# Backup volumes
docker run --rm -v template-git-setup_forgejo_data:/data -v $(pwd):/backup ubuntu tar czf /backup/forgejo_data_backup.tar.gz -C /data .
docker run --rm -v template-git-setup_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_data_backup.tar.gz -C /data .

# Backup runner configs
tar czf runner_configs_backup.tar.gz runners/
```

## Runners

### Adding More Runners

1. Add a new dind service and runner service in `docker-compose.yml`:

```yaml
dind-runner3:
  image: docker:dind
  container_name: forgejo-dind-runner3
  privileged: true
  restart: unless-stopped
  command: ["dockerd", "-H", "tcp://0.0.0.0:2375", "--tls=false"]
  networks:
    - forgejo_net

runner3:
  image: data.forgejo.org/forgejo/runner:11
  container_name: forgejo-runner3
  restart: unless-stopped
  depends_on:
    dind-runner3:
      condition: service_started
  environment:
    DOCKER_HOST: tcp://dind-runner3:2375
  user: "1001:1001"
  volumes:
    - ./runners/runner3:/data
  command: '/bin/sh -c "sleep 5; forgejo-runner daemon --config /data/config.yml"'
  networks:
    - forgejo_net
```

2. Create the directory: `mkdir -p runners/runner3 && sudo chown -R 1001:1001 runners/runner3`
3. Register the runner: `./register-runner.sh runner3`
4. Restart: `docker compose restart runner3`

### Runner Labels

The runners are configured with these labels:
- `docker:docker://node:20` - Runs jobs in a Node.js 20 container
- `ubuntu-latest:docker://catthehacker/ubuntu:act-latest` - Ubuntu environment

You can customize labels during registration to support different environments.

## Troubleshooting

### Forgejo doesn't start
- Check logs: `docker compose logs forgejo`
- Ensure PostgreSQL is healthy: `docker compose ps postgres`
- Verify environment variables are correct

### Caddy SSL issues
- Ensure ports 80 and 443 are accessible from the internet
- Check Caddy logs: `docker compose logs caddy`
- Verify DNS is pointing to your server

### Runners not picking up jobs
- Check runner logs: `docker compose logs runner1`
- Verify runners are registered: Visit `https://your-domain.com/admin/actions/runners`
- Ensure runner config exists: `ls -la runners/runner1/config.yml`
- Restart runners: `docker compose restart runner1 runner2`

### Permission issues with runners
```bash
sudo chown -R 1001:1001 runners/
chmod -R 755 runners/
docker compose restart runner1 runner2
```

## SSH Access

Git SSH operations are available on port 2222:

```bash
git clone ssh://git@your-domain.com:2222/username/repo.git
```

Configure in `~/.ssh/config`:

```
Host your-domain.com
    Port 2222
    User git
```

Then you can use standard git commands:

```bash
git clone git@your-domain.com:username/repo.git
```

## Security Notes

- **Change default passwords** in `docker-compose.yml`
- Keep Docker and all images up to date
- Consider using Docker secrets for sensitive data in production
- Restrict PostgreSQL access to the Forgejo network only (already configured)
- Review Forgejo's security settings in the admin panel
- Consider enabling 2FA for administrator accounts

## Contributing

For AI agents working on this repository, see [agents.md](agents.md) for guidelines and context.

## License

See the LICENSE file for details.

## Additional Resources

- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions (CI/CD) Documentation](https://forgejo.org/docs/latest/user/actions/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
