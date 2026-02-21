# AI Agent Collaboration Guide

This document provides context and guidelines for AI agents working on this repository.

## Repository Purpose

This repository provides a production-ready Docker Compose setup for running **Forgejo**, a self-hosted Git service. It includes:

- Forgejo server with PostgreSQL database
- Caddy reverse proxy with automatic HTTPS
- CI/CD runners (Docker-in-Docker) for Forgejo Actions
- Setup and management scripts

**Target users**: System administrators, DevOps engineers, and development teams who want to self-host their Git repositories with integrated CI/CD.

## Repository Structure

```
template-git-setup/
├── docker-compose.yml       # Main Docker Compose configuration
├── Caddyfile               # Caddy reverse proxy config
├── README.md               # User-facing documentation
├── agents.md               # This file - AI collaboration guide
├── setup-directories.sh    # Script to create runner directories
├── register-runner.sh      # Script to register runners with Forgejo
├── start.sh                # Convenience script to start services
└── runners/                # Runner configuration (created by setup)
    ├── runner1/
    └── runner2/
```

## Key Technologies

- **Forgejo**: Self-hosted Git service (fork of Gitea)
- **Docker & Docker Compose**: Containerization and orchestration
- **PostgreSQL**: Database backend for Forgejo
- **Caddy**: Web server with automatic HTTPS
- **Forgejo Actions**: CI/CD system (GitHub Actions compatible)
- **Docker-in-Docker (dind)**: Enables runners to execute containerized jobs

## Architecture Overview

### Services

1. **postgres**: PostgreSQL 18 database
   - Stores all Forgejo data (repos, users, issues, etc.)
   - Health checks ensure Forgejo waits for DB to be ready

2. **forgejo**: Main Git service
   - Exposes port 3000 internally (proxied by Caddy)
   - SSH on port 2222 for git operations
   - Depends on PostgreSQL

3. **caddy**: Reverse proxy
   - Handles HTTPS with automatic Let's Encrypt certificates
   - Proxies requests to Forgejo on port 3000
   - Exposes ports 80 and 443

4. **dind-runner1/2**: Docker-in-Docker engines
   - Privileged containers that run Docker daemon
   - Used by runners to execute CI/CD jobs in containers

5. **runner1/2**: Forgejo Action runners
   - Execute CI/CD workflows
   - Connect to dind containers for Docker operations
   - Must be registered with Forgejo to become active

### Networks & Volumes

- **forgejo_net**: Internal network for service communication
- **postgres_data**: Persistent PostgreSQL data
- **forgejo_data**: Persistent Forgejo data (repositories, config)
- **caddy_data**: Persistent Caddy data (certificates)
- **caddy_config**: Persistent Caddy configuration

## Common Tasks

### Adding a New Runner

1. **Add services to docker-compose.yml**:
   ```yaml
   dind-runner3:
     image: docker:dind
     # ... (copy from existing dind-runner)
   
   runner3:
     image: data.forgejo.org/forgejo/runner:11
     # ... (copy from existing runner, update name/volume)
   ```

2. **Create directory**: `mkdir -p runners/runner3`
3. **Set permissions**: `chown 1001:1001 runners/runner3`
4. **Start service**: `docker compose up -d runner3 dind-runner3`
5. **Register**: `./register-runner.sh runner3`

### Updating Forgejo Version

1. Change image tag in docker-compose.yml: `codeberg.org/forgejo/forgejo:XX` (note: Forgejo server uses codeberg.org registry, while runners use data.forgejo.org)
2. Pull new image: `docker compose pull forgejo`
3. Restart: `docker compose up -d forgejo`
4. Check logs: `docker compose logs -f forgejo`

### Customizing Runner Labels

Edit the labels during registration or modify config.yml:
```yaml
labels:
  - 'ubuntu-latest:docker://catthehacker/ubuntu:act-latest'
  - 'node:docker://node:20'
  - 'python:docker://python:3.11'
```

### Troubleshooting Common Issues

1. **Runner not picking up jobs**:
   - Check if registered: Forgejo UI → Admin → Actions → Runners
   - Verify config.yml exists: `ls runners/runner1/config.yml`
   - Check logs: `docker compose logs runner1`
   - Restart: `docker compose restart runner1`

2. **Permission errors**:
   - Runners run as UID/GID 1001
   - Fix: `chown -R 1001:1001 runners/`

3. **Database connection errors**:
   - Ensure PostgreSQL is healthy: `docker compose ps postgres`
   - Check password matches in both services
   - Verify network connectivity

## Development Guidelines

### When Modifying docker-compose.yml

- **Maintain service dependencies**: Forgejo depends on postgres, runners depend on dind
- **Keep health checks**: They ensure proper startup order
- **Preserve volumes**: Data persistence is critical
- **Document environment variables**: Add comments for new config options
- **Test with clean state**: `docker compose down -v` to remove volumes

### When Updating Scripts

- **Maintain POSIX compatibility**: Use `/bin/bash` for advanced features, but avoid bashisms when possible
- **Add error handling**: Use `set -e` and check command outputs
- **Provide user feedback**: Use colored output and clear messages
- **Include validation**: Check prerequisites and fail early
- **Make scripts idempotent**: Safe to run multiple times

### When Updating Documentation

- **Keep README.md user-focused**: Step-by-step instructions for end users
- **Keep agents.md technical**: Architecture and development details for AI agents
- **Include examples**: Real commands users can copy-paste
- **Link to official docs**: Don't duplicate, reference authoritative sources
- **Update both files**: README for user impact, agents.md for technical changes

## Security Considerations

1. **Change default passwords**: Never commit real passwords
2. **UID/GID 1001**: Runners should not run as root
3. **Privileged containers**: dind containers require privileged mode (known limitation)
4. **Network isolation**: Keep forgejo_net internal
5. **HTTPS required**: Caddy handles this automatically
6. **Update regularly**: Keep all images up to date

## Testing Changes

### Local Testing

1. **Clean start**: `docker compose down -v && ./setup-directories.sh && ./start.sh`
2. **Verify services**: `docker compose ps` (all should be healthy)
3. **Test registration**: `./register-runner.sh runner1` (requires Forgejo setup)
4. **Check logs**: `docker compose logs` for any errors
5. **Test workflow**: Create a simple workflow in Forgejo to verify runners work

### Validation Checklist

- [ ] All services start successfully
- [ ] Forgejo accessible via web UI
- [ ] PostgreSQL connection works
- [ ] Caddy serves HTTPS correctly
- [ ] Runners can be registered
- [ ] Runners pick up and execute jobs
- [ ] Scripts run without errors
- [ ] Documentation reflects changes

## Workflow for AI Agents

### Making Changes

1. **Understand the context**: Read this file and README.md first
2. **Identify affected components**: Determine which files need changes
3. **Make minimal changes**: Surgical edits to accomplish the goal
4. **Update documentation**: README.md for users, agents.md for technical details
5. **Test locally if possible**: Verify changes don't break existing functionality
6. **Document trade-offs**: Explain any limitations or caveats

### Communication

- **Be explicit**: State what you changed and why
- **Highlight risks**: Point out any potential issues
- **Suggest alternatives**: If you see a better approach
- **Ask for clarification**: If requirements are ambiguous

## Additional Resources

- [Forgejo Documentation](https://forgejo.org/docs/latest/)
- [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker-in-Docker Considerations](https://hub.docker.com/_/docker)

## Version History

- **2024**: Initial setup with Forgejo 13, PostgreSQL 18, 2 runners
- Document created for AI collaboration with comprehensive technical context

---

*This document should be updated whenever significant changes are made to the repository structure, architecture, or workflows.*
