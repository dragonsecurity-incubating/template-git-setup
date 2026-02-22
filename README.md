# Forgejo Setup with Docker Compose

A complete Docker Compose setup for running [Forgejo](https://forgejo.org/) (a self-hosted Git service) with Caddy as a reverse proxy, PostgreSQL database, and automated CI/CD runners.

## Overview

This setup includes:
- **Forgejo**: Self-hosted Git service (similar to GitHub/GitLab)
- **PostgreSQL**: Database backend
- **Caddy**: Automatic HTTPS reverse proxy
- **2 CI/CD Runners**: Docker-in-Docker runners for running workflows
- **Renovate**: Automated dependency updates (optional)

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

### 5. Configure Renovate (Optional)

Renovate automatically creates pull requests to update dependencies in your repositories. To enable it:

1. **Create a bot user in Forgejo**:
   - Register a new user account (e.g., "renovate-bot")
   - Generate a Personal Access Token (PAT) for this user
   - Go to: Settings → Applications → Generate New Token
   - Required scopes: `repo` (full control of repositories)

2. **Create a GitHub Personal Access Token** (for fetching release notes):
   - Go to: https://github.com/settings/tokens
   - Generate a new token (classic)
   - Required scopes: `public_repo` (or `repo` for private repos)

3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env and add your tokens:
   # RENOVATE_TOKEN=your_forgejo_bot_pat
   # RENOVATE_GITHUB_TOKEN=your_github_pat
   ```

4. **Update domain in docker-compose.yml**:
   ```yaml
   # In the renovate service section:
   RENOVATE_ENDPOINT: "https://your-domain.com/api/v1"
   RENOVATE_GIT_AUTHOR: "Renovate Bot <renovate-bot@your-domain.com>"
   GIT_AUTHOR_EMAIL: "renovate-bot@your-domain.com"
   GIT_COMMITTER_EMAIL: "renovate-bot@your-domain.com"
   ```

5. **Customize Renovate configuration** (optional):
   - Edit `renovate/config.js` to adjust behavior
   - See [Renovate docs](https://docs.renovatebot.com/) for options

**Note**: If you don't want to use Renovate, you can disable it by commenting out the `renovate` service in `docker-compose.yml` or simply not creating the `.env` file with tokens.

### 6. Create Required Directories

Run the setup script to create directories with proper permissions:

```bash
./setup-directories.sh
```

Or manually:

```bash
mkdir -p runners/runner1 runners/runner2 renovate
sudo chown -R 1001:1001 runners/
chmod -R 755 runners/
```

### 7. Start the Services

```bash
docker compose up -d
```

Wait for all services to start (about 30 seconds). Check status:

```bash
docker compose ps
```

### 8. Initial Forgejo Configuration

Visit your domain (e.g., `https://your-domain.com`) and complete the initial setup:

1. Database settings should already be configured via environment variables
2. Create your administrator account
3. Configure any additional settings as needed

### 9. Register the Runners

After Forgejo is running, register the runners to enable CI/CD:

```bash
./register-runner.sh runner1
./register-runner.sh runner2
```

The registration process creates a `.runner` file for each runner containing the registration token and instance information. The runner will use default settings unless you provide a custom `config.yml`.

Or manually for each runner:

```bash
# Get a runner registration token from Forgejo:
# Go to: https://your-domain.com/admin/actions/runners
# Click "Create new Runner" and copy the registration token

# Register runner1
docker compose exec runner1 forgejo-runner register \
  --no-interactive \
  --instance https://your-domain.com \
  --token YOUR_REGISTRATION_TOKEN \
  --name runner1 \
  --labels docker:docker://node:20,ubuntu-latest:docker://catthehacker/ubuntu:act-latest

# Register runner2
docker compose exec runner2 forgejo-runner register \
  --no-interactive \
  --instance https://your-domain.com \
  --token YOUR_REGISTRATION_TOKEN \
  --name runner2 \
  --labels docker:docker://node:20,ubuntu-latest:docker://catthehacker/ubuntu:act-latest

# Restart runners to apply configuration
docker compose restart runner1 runner2
```

**Optional**: To customize runner behavior, you can generate and edit a config file:
```bash
docker compose exec runner1 forgejo-runner generate-config > runners/runner1/config.yml
# Edit runners/runner1/config.yml as needed
docker compose restart runner1
```

## Directory Structure

```
template-git-setup/
├── docker-compose.yml      # Main Docker Compose configuration
├── Caddyfile              # Caddy reverse proxy configuration
├── .env.example           # Template for environment variables
├── setup-directories.sh   # Script to create required directories
├── register-runner.sh     # Script to register runners
├── start.sh               # Convenience script to start everything
├── runners/
│   ├── runner1/           # Runner 1 configuration and data
│   │   ├── .runner        # Registration file (required)
│   │   └── config.yml     # Optional custom config
│   └── runner2/           # Runner 2 configuration and data
│       ├── .runner        # Registration file (required)
│       └── config.yml     # Optional custom config
├── renovate/
│   └── config.js          # Renovate configuration
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
- **Renovate cache**: Docker volume `renovate_cache`

```bash
# Backup volumes
docker run --rm -v template-git-setup_forgejo_data:/data -v $(pwd):/backup ubuntu tar czf /backup/forgejo_data_backup.tar.gz -C /data .
docker run --rm -v template-git-setup_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_data_backup.tar.gz -C /data .

# Backup runner configs
tar czf runner_configs_backup.tar.gz runners/
```

## Renovate - Automated Dependency Updates

Renovate automatically scans your repositories for outdated dependencies and creates pull requests to update them. This keeps your projects secure and up-to-date with minimal manual effort.

### How Renovate Works

1. **Periodic Scanning**: Renovate runs on a schedule (every 10 minutes by default in this setup)
2. **Autodiscovery**: It automatically finds all repositories the bot user has access to
3. **Dependency Detection**: Detects dependencies in various file formats (package.json, Dockerfile, etc.)
4. **Pull Request Creation**: Creates PRs with dependency updates
5. **Release Notes**: Fetches changelogs from GitHub (requires GITHUB_TOKEN)

### Configuring Renovate Behavior

Edit `renovate/config.js` to customize Renovate's behavior:

```javascript
module.exports = {
  platform: 'forgejo',
  endpoint: 'https://git.example.com/api/v1',
  autodiscover: true,
  onboarding: true,  // Creates an initial PR to configure Renovate per-repo
  prHourlyLimit: 2,  // Max PRs per hour to avoid spam
  prConcurrentLimit: 10,  // Max open PRs at once
  
  // Schedule when Renovate runs (optional)
  // schedule: ['after 10pm every weekday', 'before 5am every weekday', 'every weekend'],
  
  // Automerge options (optional)
  // automerge: true,
  // automergeType: 'pr',
  
  // Group updates (optional)
  // packageRules: [
  //   {
  //     groupName: 'all non-major dependencies',
  //     groupSlug: 'all-minor-patch',
  //     matchPackagePatterns: ['*'],
  //     matchUpdateTypes: ['minor', 'patch'],
  //   },
  // ],
  
  hostRules: [
    {
      matchHost: 'github.com',
      token: process.env.RENOVATE_GITHUB_TOKEN,
    },
    {
      matchHost: 'api.github.com',
      token: process.env.RENOVATE_GITHUB_TOKEN,
    },
  ],
};
```

### Per-Repository Configuration

After Renovate creates the onboarding PR in a repository, you can customize its behavior per-repository by editing the `renovate.json` file:

```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    }
  ]
}
```

### Troubleshooting Renovate

**Renovate not creating PRs:**
- Check logs: `docker compose logs -f renovate`
- Verify the bot user has access to repositories
- Ensure tokens are correctly set in `.env`
- Check that `RENOVATE_ENDPOINT` matches your Forgejo URL

**GitHub rate limiting:**
- Ensure `RENOVATE_GITHUB_TOKEN` is set
- The token allows Renovate to fetch release notes without hitting rate limits

**Adjusting scan frequency:**
- Edit the `sleep` value in the renovate service command (docker-compose.yml)
- Default is 600 seconds (10 minutes)
- Example: Change to `sleep 3600` for hourly scans

**Disable Renovate:**
- Comment out the `renovate` service in docker-compose.yml, or
- Stop it: `docker compose stop renovate`

### Supported Dependency Types

Renovate supports many package managers and dependency types:
- **Docker**: Dockerfile, docker-compose.yml
- **JavaScript/Node**: package.json, package-lock.json
- **Python**: requirements.txt, Pipfile, pyproject.toml
- **Go**: go.mod
- **Ruby**: Gemfile
- **Java**: pom.xml, build.gradle
- **And many more...**

For a complete list, see the [Renovate documentation](https://docs.renovatebot.com/modules/manager/).

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
  command: '/bin/sh -c "sleep 5; if [ -f /data/.runner ]; then forgejo-runner daemon; else echo \"Waiting for registration...\"; while : ; do sleep 1 ; done; fi"'
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
- Ensure runner registration file exists: `ls -la runners/runner1/.runner`
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

## Package Registry

Forgejo includes a built-in package registry that supports multiple package types:
- **Container/Docker images**: `docker pull your-domain.com/owner/package:tag`
- **npm packages**: JavaScript/Node.js packages
- **PyPI packages**: Python packages
- **Maven packages**: Java packages
- **And more...**

The package registry is enabled by default in this setup via:
```yaml
FORGEJO__packages__ENABLED: "true"
FORGEJO__packages__CONTAINER__ENABLED: "true"
```

To use the container registry:

1. **Login to the registry**:
   ```bash
   docker login your-domain.com
   # Use your Forgejo username and password
   ```

2. **Tag and push images**:
   ```bash
   docker tag myimage:latest your-domain.com/username/myimage:latest
   docker push your-domain.com/username/myimage:latest
   ```

3. **Pull images**:
   ```bash
   docker pull your-domain.com/username/myimage:latest
   ```

For other package types, see the [Forgejo Packages documentation](https://forgejo.org/docs/latest/user/packages/).

## Security Notes

- **Change default passwords** in `docker-compose.yml`
- **Protect your .env file**: Never commit it to git (it's in .gitignore)
- **Secure your tokens**: Use strong, unique tokens for Renovate
- Keep Docker and all images up to date
- Consider using Docker secrets for sensitive data in production
- Restrict PostgreSQL access to the Forgejo network only (already configured)
- Review Forgejo's security settings in the admin panel
- Consider enabling 2FA for administrator accounts
- Limit Renovate bot permissions to only repositories it needs to update

## Contributing

For AI agents working on this repository, see [agents.md](agents.md) for guidelines and context.

## License

See the LICENSE file for details.

## Additional Resources

- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions (CI/CD) Documentation](https://forgejo.org/docs/latest/user/actions/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
