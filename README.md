# Forgejo Setup with Docker Compose

A complete Docker Compose setup for running [Forgejo](https://forgejo.org/) (a self-hosted Git service) with Caddy as a reverse proxy, PostgreSQL database, and automated CI/CD runners.

## Overview

This setup includes:
- **Forgejo**: Self-hosted Git service (similar to GitHub/GitLab)
- **PostgreSQL**: Database backend
- **Caddy**: Automatic HTTPS reverse proxy
- **2 CI/CD Runners**: Docker-in-Docker runners for running workflows
- **Renovate**: Automated dependency updates (optional)
- **Ollama**: Local LLM backend for AI-powered tools (optional)
- **AuditLM**: AI-powered code audit and security scanning (optional)
- **Forgejo MCP**: Model Context Protocol server for AI assistant integration (optional)

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
├── auditlm/               # AuditLM Dockerfiles
│   ├── Dockerfile         # Main AuditLM service image
│   └── analysis/          # Custom analysis container
│       └── Dockerfile     # Minimal analysis environment
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

## AI-Powered Services (Optional)

This setup includes three optional AI-powered services for code analysis, security auditing, and AI assistant integration. These services work together to provide intelligent code review and programmatic access to your Forgejo instance.

### Ollama - Local LLM Backend

**Ollama** provides a local large language model (LLM) backend that powers the AuditLM service. It runs AI models locally without sending your code to external services.

**Features**:
- Run AI models locally on your infrastructure
- Supports various open-source models (Qwen, Llama, Mistral, etc.)
- Optional GPU acceleration for faster inference
- No external API calls or data sharing

**Setup**:

1. The Ollama service is included in `docker-compose.yml` and will start automatically
2. Download the required model for AuditLM:
   ```bash
   docker exec -it forgejo-ollama ollama pull qwen2.5-coder:7b-instruct
   ```
3. Wait for the model to download (may take several minutes depending on model size)

**GPU Acceleration** (optional):

If you have an NVIDIA GPU, add this to the ollama service in `docker-compose.yml`:
```yaml
ollama:
  image: ollama/ollama:latest
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
  # ... rest of config
```

**CPU/Thread Allocation** (optional):

By default, Ollama uses all available CPUs. To allocate more (or limit) CPU resources, add these settings to the ollama service in `docker-compose.yml`:

```yaml
ollama:
  image: ollama/ollama:latest
  cpus: 4.0                    # Allocate 4 CPUs (use decimals like 2.5 for fractional allocation)
  # Or pin to specific CPU cores for better performance:
  cpuset_cpus: "0-3"           # Use CPU cores 0 through 3
  # Optional: Increase CPU priority
  cpu_shares: 2048             # Double the default priority (default is 1024)
  # ... rest of config
```

**Performance Tuning Environment Variables**:

You can also configure Ollama's behavior with environment variables:
```yaml
ollama:
  environment:
    - OLLAMA_NUM_PARALLEL=4      # Number of parallel requests (default: auto-detected)
    - OLLAMA_MAX_LOADED_MODELS=1 # Max models kept in memory (default: 1)
  # ... rest of config
```

**When to allocate more CPUs**:
- **Large models**: Models like 13B or 70B benefit from more CPU cores
- **Multiple requests**: If AuditLM handles many repositories simultaneously
- **Faster inference**: More CPUs reduce response time for code analysis

**Available Models**:
- `qwen2.5-coder:7b-instruct` - Default, optimized for code (7GB)
- `codellama:7b` - Meta's code-focused model (3.8GB)
- `deepseek-coder:6.7b` - Specialized for code generation (3.8GB)
- See [Ollama library](https://ollama.com/library) for more models

**Manage Models**:
```bash
# List downloaded models
docker exec -it forgejo-ollama ollama list

# Pull a different model
docker exec -it forgejo-ollama ollama pull codellama:7b

# Remove a model
docker exec -it forgejo-ollama ollama rm qwen2.5-coder:7b-instruct
```

### AuditLM - AI-Powered Code Auditing

**AuditLM** automatically analyzes your code for security vulnerabilities, code quality issues, and best practice violations using AI. It reviews pull requests and commits, then posts findings as comments or issues.

**Features**:
- AI-powered security vulnerability detection
- Code quality and best practice analysis
- Automated PR reviews with inline comments
- Sandboxed analysis in Docker containers
- Customizable analysis environments

**Setup**:

1. **Create a bot user** in Forgejo:
   - Username: `auditlm-bot` (recommended)
   - Generate a Personal Access Token with scopes: `repo`, `write:issue`
   - See [BOT_USERS.md](BOT_USERS.md) for detailed instructions

2. **Configure environment variables**:
   ```bash
   # Add to .env file
   AUDITLM_TOKEN=your_auditlm_bot_pat_here
   ```

3. **Customize analysis** (optional):
   Edit the auditlm service in `docker-compose.yml`:
   ```yaml
   auditlm:
     command: >
       forgejo
       --model "qwen2.5-coder:7b-instruct"  # AI model to use
       --socket "/var/run/docker.sock"
       --base-url "http://ollama:11434/v1"
       --forgejo-url "https://your-domain.com"
       --image "rust:1-trixie"  # Analysis container image
   ```

4. **Grant repository access**:
   - Add `auditlm-bot` as a collaborator to repositories you want audited
   - Or add the bot to an organization team with appropriate access

5. **Start the service**:
   ```bash
   docker compose up -d auditlm
   ```

**How It Works**:
1. AuditLM monitors your Forgejo instance for new commits and PRs
2. When triggered, it pulls the code into a sandboxed Docker container
3. The AI model analyzes the code for issues
4. Results are posted as PR review comments or GitHub issues
5. The analysis container is cleaned up after each run

**Supported Languages**:
- Change the `--image` parameter to match your project's language
- Examples: `node:20-alpine`, `python:3.11-slim`, `golang:1.21`, `openjdk:17`
- The image should have necessary build tools for your project

**Custom Analysis Image**:

This repository includes a minimal analysis container (`auditlm/analysis/Dockerfile`) that provides a lightweight alternative to language-specific images. It's based on Debian Bookworm Slim with only git and ca-certificates installed.

**When to use the custom analysis image**:
- For lightweight analysis without heavy language toolchains
- When you only need git operations and basic file analysis
- To minimize image size and startup time
- For projects that don't require compilation or building

**Building the custom analysis image**:
```bash
# Build the image with a tag
docker build -t auditlm-analysis:latest ./auditlm/analysis/

# Or with a specific name
docker build -t my-org/auditlm-analysis:v1.0 ./auditlm/analysis/
```

**Using the custom analysis image**:

1. Build the image first (see above)
2. Update `docker-compose.yml` to use your custom image:
   ```yaml
   auditlm:
     command: >
       forgejo
       --model "qwen2.5-coder:7b-instruct"
       --socket "/var/run/docker.sock"
       --base-url "http://ollama:11434/v1"
       --forgejo-url "http://forgejo:3000"
       --image "auditlm-analysis:latest"  # Use your custom image
   ```
3. Restart the service:
   ```bash
   docker compose restart auditlm
   ```

**Customizing the analysis image**:

You can modify `auditlm/analysis/Dockerfile` to add tools specific to your needs:
```dockerfile
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates \
    # Add your custom tools here:
    python3 nodejs npm \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /work
```

Then rebuild and update the `--image` parameter in docker-compose.yml.

**Troubleshooting**:
```bash
# Check AuditLM logs
docker compose logs -f auditlm

# Verify Ollama model is available
docker exec -it forgejo-ollama ollama list

# Check Docker socket permissions
ls -la /var/run/docker.sock

# Restart AuditLM
docker compose restart auditlm
```

### Forgejo MCP - AI Assistant Integration

**Forgejo MCP** (Model Context Protocol) provides a standardized API for AI coding assistants to access your Forgejo repositories, users, and organizations. This enables AI assistants like Claude Desktop, Cursor, and GitHub Copilot to work directly with your self-hosted Git service.

**Features**:
- MCP-compliant API for AI assistant integration
- Read-only access to repositories (configurable)
- Query users and organizations
- Secure authentication via basic auth or IP allowlist
- Separate subdomain with SSL

**Setup**:

1. **Create a bot user** in Forgejo:
   - Username: `mcp-bot` (recommended)
   - Generate a Personal Access Token with scopes: `repo` (read), `read:user`, `read:organization`
   - See [BOT_USERS.md](BOT_USERS.md) for detailed instructions

2. **Configure environment variables**:
   ```bash
   # Add to .env file
   FORGEJO_MCP_TOKEN=your_mcp_bot_pat_here
   ```

3. **Configure the MCP subdomain**:
   Edit `Caddyfile` to replace `mcp.example.com` with your actual subdomain:
   ```
   mcp.your-domain.com {
       encode zstd gzip
       basicauth {
           mcpuser $2a$14$...  # See security section below
       }
       reverse_proxy forgejo-mcp:8080
   }
   ```

4. **Set up DNS**:
   - Create an A record for `mcp.your-domain.com` pointing to your server
   - Caddy will automatically obtain an SSL certificate

5. **Grant repository access**:
   - Add `mcp-bot` as a read-only collaborator to repositories you want accessible via MCP
   - Or add the bot to an organization with read-only access

6. **Start the service**:
   ```bash
   docker compose up -d forgejo-mcp
   ```

**Security Configuration**:

The MCP endpoint should be protected since it provides API access to your repositories. Two options are provided:

**Option A: Basic Authentication** (recommended for most users):
```bash
# Generate a new password hash
docker run --rm caddy caddy hash-password --plaintext 'your-secure-password'

# Update Caddyfile with the hash
basicauth {
    mcpuser $2a$14$YOUR_HASHED_PASSWORD_HERE
}
```

**Option B: IP Allowlist** (for static IPs):
```
# Uncomment and edit in Caddyfile
@allowed remote_ip 203.0.113.10 198.51.100.0/24
abort @allowed
```

**Using MCP with AI Assistants**:

1. **Claude Desktop**:
   Add to your Claude Desktop config:
   ```json
   {
     "mcpServers": {
       "forgejo": {
         "url": "https://mcp.your-domain.com/",
         "auth": {
           "type": "basic",
           "username": "mcpuser",
           "password": "your-password"
         }
       }
     }
   }
   ```

2. **Cursor / VS Code**:
   Configure MCP endpoint in settings with authentication

3. **Test connection**:
   ```bash
   curl -u mcpuser:your-password https://mcp.your-domain.com/health
   ```

**Troubleshooting**:
```bash
# Check MCP logs
docker compose logs -f forgejo-mcp

# Test without auth (from server)
curl http://localhost:8080/health

# Check Caddy is routing correctly
docker compose logs caddy

# Verify bot has repo access in Forgejo UI
```

### Bot User Management

All three AI services require separate bot user accounts in Forgejo with specific permissions. This follows security best practices by:
- Limiting each bot to only the permissions it needs
- Making it easy to revoke access if needed
- Providing clear audit trails of bot activity

**Summary**:

| Bot User | Service | Required Scopes | Can Write? |
|----------|---------|-----------------|------------|
| `renovate-bot` | Renovate | `repo`, `write:package` | Yes |
| `auditlm-bot` | AuditLM | `repo`, `write:issue` | Yes |
| `mcp-bot` | Forgejo MCP | `repo` (read), `read:user`, `read:organization` | No |

**For detailed setup instructions**, see [BOT_USERS.md](BOT_USERS.md).

### Disabling AI Services

If you don't want to use the AI services:

1. **Don't create bot users or tokens** - Services will fail to authenticate
2. **Comment out services** in `docker-compose.yml`:
   ```yaml
   # ollama:
   #   ...
   # auditlm:
   #   ...
   # forgejo-mcp:
   #   ...
   ```
3. **Or stop individual services**:
   ```bash
   docker compose stop ollama auditlm forgejo-mcp
   ```

The core Forgejo, PostgreSQL, Caddy, and Runner services will work independently.

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
- **Secure your tokens**: Use strong, unique tokens for each bot service
- **Use separate bot accounts**: Never share tokens between services (see [BOT_USERS.md](BOT_USERS.md))
- **Protect MCP endpoint**: Use basic auth or IP allowlisting for the MCP service
- **Limit bot permissions**: Each bot should have minimal permissions required (principle of least privilege)
- Keep Docker and all images up to date
- Consider using Docker secrets for sensitive data in production
- Restrict PostgreSQL access to the Forgejo network only (already configured)
- Review Forgejo's security settings in the admin panel
- Consider enabling 2FA for administrator accounts
- Regularly review bot user activity in audit logs
- **AuditLM Docker socket**: Be aware that AuditLM has access to Docker socket for sandboxed analysis

## Contributing

For AI agents working on this repository, see [agents.md](agents.md) for guidelines and context.

## License

See the LICENSE file for details.

## Additional Resources

- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions (CI/CD) Documentation](https://forgejo.org/docs/latest/user/actions/)
- [Forgejo Packages Documentation](https://forgejo.org/docs/latest/user/packages/)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Ollama Model Library](https://ollama.com/library)
- [AuditLM GitHub Repository](https://github.com/ellenhp/auditlm)
- [Forgejo MCP Server](https://github.com/ronmi/forgejo-mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
