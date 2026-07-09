# Bot Users Configuration Guide

This document describes the bot users required for the various automated services in the Forgejo setup, their purposes, and the specific permissions each bot needs.

## Overview

The setup uses **three separate bot users**, each with minimal permissions required for their specific function. This follows the principle of least privilege and improves security by limiting the scope of each bot.

## Bot Users

### 1. Renovate Bot (`renovate-bot`)

**Purpose**: Automatically scans repositories for outdated dependencies and creates pull requests with updates.

**Username**: `renovate-bot` (recommended)

**Required Permissions**:
- **Scopes**: 
  - `repo` (read and write) - To read repository files and create PRs
  - `write:package` - To update dependency manifests
  
**Token Environment Variable**: `RENOVATE_TOKEN`

**Setup Instructions**:
1. In Forgejo, register a new user account named `renovate-bot`
2. Set a valid email (e.g., `renovate-bot@example.com`)
3. Log in as the bot user
4. Go to **Settings** → **Applications** → **Generate New Token**
5. Name: "Renovate Service Token"
6. Select scopes: `repo`, `write:package`
7. Generate token and copy it
8. Add the token to your `.env` file as `RENOVATE_TOKEN=<token>`

**Repository Access**:
- The bot user must be added as a collaborator to repositories you want Renovate to manage
- Alternatively, add the bot to an organization team with appropriate access
- Renovate will autodiscover all repositories the bot has access to

**Additional Notes**:
- The bot will create pull requests from branches like `renovate/dependency-name`
- You can configure auto-merge behavior in `renovate/config.js`
- Requires `RENOVATE_GITHUB_TOKEN` for fetching release notes from GitHub

---

### 2. AuditLM Bot (`auditlm-bot`)

**Purpose**: AI-powered code audit tool that analyzes pull requests and commits for security vulnerabilities, code quality issues, and best practices violations.

**Username**: `auditlm-bot` (recommended)

**Required Permissions**:
- **Scopes**:
  - `repo` (read and write) - To read code and create review comments
  - `write:issue` - To create issues for findings
  
**Token Environment Variable**: `AUDITLM_TOKEN`

**Setup Instructions**:
1. In Forgejo, register a new user account named `auditlm-bot`
2. Set a valid email (e.g., `auditlm-bot@example.com`)
3. Log in as the bot user
4. Go to **Settings** → **Applications** → **Generate New Token**
5. Name: "AuditLM Service Token"
6. Select scopes: `repo`, `write:issue`
7. Generate token and copy it
8. Add the token to your `.env` file as `AUDITLM_TOKEN=<token>`

**Repository Access**:
- The bot user must be added as a collaborator to repositories you want AuditLM to audit
- Recommended: Add to organization with read/write access to all repositories
- AuditLM monitors repositories for new commits and PRs automatically

**Additional Notes**:
- AuditLM uses the Ollama service (LLM backend) for AI-powered analysis
- The bot uses Docker-in-Docker to run sandboxed analysis containers
- You can customize the AI model and analysis image in `docker-compose.yml`
- Default model: `qwen2.5-coder:7b-instruct`
- Default analysis image: `rust:1-trixie` (full Rust environment)
- Custom analysis image: Build from `auditlm/analysis/Dockerfile` for a minimal environment

**Analysis Container Image Options**:
1. **Use default image** (`rust:1-trixie`): Good for Rust projects or when compilation is needed
2. **Build custom image**: `docker build -t auditlm-analysis:latest ./auditlm/analysis/`
   - Minimal Debian with git and ca-certificates
   - Customize by editing `auditlm/analysis/Dockerfile` to add tools
   - Update `--image` parameter in docker-compose.yml to use custom image
3. **Use language-specific image**: e.g., `node:20-alpine`, `python:3.11-slim`, `golang:1.21`

See README.md for detailed instructions on building and using custom analysis images.

**LLM Requirements**:
- Ensure the Ollama service has the specified model downloaded
- To download a model: `docker exec -it forgejo-ollama ollama pull qwen2.5-coder:7b-instruct`
- For GPU acceleration, see Ollama documentation on adding runtime/device configurations

---

### 3. Forgejo MCP Bot (`mcp-bot`)

**Purpose**: Model Context Protocol (MCP) server that provides programmatic access to Forgejo repositories, users, and organizations for AI assistants and automation tools.

**Username**: `mcp-bot` (recommended)

**Required Permissions**:
- **Scopes**:
  - `repo` (read only) - To access repository contents
  - `read:user` - To query user information
  - `read:organization` - To query organization information
  
**Token Environment Variable**: `FORGEJO_MCP_TOKEN`

**Setup Instructions**:
1. In Forgejo, register a new user account named `mcp-bot`
2. Set a valid email (e.g., `mcp-bot@example.com`)
3. Log in as the bot user
4. Go to **Settings** → **Applications** → **Generate New Token**
5. Name: "MCP Service Token"
6. Select scopes: `repo`, `read:user`, `read:organization`
7. Generate token and copy it
8. Add the token to your `.env` file as `FORGEJO_MCP_TOKEN=<token>`

**Repository Access**:
- The bot user must be added as a collaborator (read-only) to repositories you want accessible via MCP
- Recommended: Add to organization with read-only access
- MCP provides API access to any repository the bot can see

**Additional Notes**:
- The MCP server is exposed on a separate subdomain: `mcp.example.com`
- **Security**: The MCP endpoint is protected by basic authentication (see Caddyfile)
- Default credentials are in the Caddyfile (username: `mcpuser`, password hashed with bcrypt)
- To generate a new password hash: `docker run --rm caddy caddy hash-password --plaintext 'your-password'`
- Alternatively, use IP allowlisting instead of basic auth (see Caddyfile comments)
- MCP is typically used by AI coding assistants like Claude Desktop, Cursor, or Copilot

**MCP Usage Example**:
```bash
# Test MCP endpoint (requires basic auth)
curl -u mcpuser:your-password https://mcp.example.com/health

# AI assistants connect to: https://mcp.example.com/
```

---

## Security Best Practices

### Token Management
1. **Never commit tokens to git** - They are in `.gitignore` for a reason
2. **Use strong, unique tokens** - Generate separate tokens for each bot
3. **Rotate tokens regularly** - Especially if a token may have been exposed
4. **Store tokens securely** - Use Docker secrets in production environments
5. **Revoke unused tokens** - Check Forgejo Settings → Applications regularly

### Permission Principle
1. **Least privilege** - Each bot has only the permissions it needs
2. **Separate accounts** - Never share tokens between services
3. **Read-only when possible** - MCP bot only needs read access
4. **Monitor activity** - Check bot user activity logs regularly

### Access Control
1. **Limit repository access** - Don't give bots access to sensitive repos unless needed
2. **Organization teams** - Use teams to manage bot access across multiple repos
3. **Audit logs** - Review Forgejo audit logs for bot activity
4. **IP restrictions** - Consider restricting bot access by IP (especially MCP)

### Production Recommendations
1. **Use Docker secrets** instead of environment variables for tokens
2. **Enable 2FA** for human administrator accounts
3. **Set up monitoring** for unusual bot activity
4. **Regular updates** - Keep all images up to date (Renovate helps with this!)
5. **Backup tokens** - Store tokens in a secure password manager
6. **Network segmentation** - Consider isolating the forgejo_net network

---

## Token Scopes Reference

Forgejo supports the following token scopes:

| Scope | Read | Write | Description |
|-------|------|-------|-------------|
| `repo` | ✓ | ✓ | Full access to repositories (code, PRs, issues) |
| `repo:status` | ✓ | ✓ | Access to commit statuses |
| `public_repo` | ✓ | ✓ | Access to public repositories only |
| `write:package` | ✓ | ✓ | Access to packages (container registry, npm, etc.) |
| `read:package` | ✓ | - | Read-only access to packages |
| `write:org` | ✓ | ✓ | Full access to organizations |
| `read:org` | ✓ | - | Read-only access to organizations |
| `write:user` | ✓ | ✓ | Update user profile |
| `read:user` | ✓ | - | Read user profile |
| `write:issue` | ✓ | ✓ | Create and update issues |
| `read:issue` | ✓ | - | Read issues |

---

## Troubleshooting

### Bot token not working
1. Verify token is copied correctly (no extra spaces)
2. Check token hasn't expired or been revoked
3. Ensure bot user has access to the repository
4. Check token has correct scopes
5. Review service logs: `docker compose logs <service-name>`

### Bot not creating PRs/comments
1. Verify bot is added as a collaborator
2. Check repository permissions for the bot user
3. Ensure bot has `write` scope if it needs to create content
4. Review Forgejo audit logs for permission errors

### MCP authentication failing
1. Verify basic auth credentials in Caddyfile
2. Check MCP service is running: `docker compose ps forgejo-mcp`
3. Test without auth from internal network first
4. Review Caddy logs: `docker compose logs caddy`

### AuditLM not analyzing code
1. Ensure Ollama has the model downloaded
2. Check Docker socket is accessible: `ls -la /var/run/docker.sock`
3. Verify bot has repository access
4. Review AuditLM logs: `docker compose logs auditlm`

---

## Summary

| Bot User | Service | Primary Function | Key Scopes | Can Write? |
|----------|---------|------------------|------------|------------|
| `renovate-bot` | Renovate | Dependency updates | `repo`, `write:package` | Yes |
| `auditlm-bot` | AuditLM | Code auditing | `repo`, `write:issue` | Yes |
| `mcp-bot` | Forgejo MCP | API access for AI | `repo` (read), `read:user`, `read:organization` | No |

---

## Additional Resources

- [Forgejo API Documentation](https://forgejo.org/docs/latest/api/)
- [Renovate Documentation](https://docs.renovatebot.com/)
- [AuditLM GitHub Repository](https://github.com/ellenhp/auditlm)
- [Forgejo MCP Server](https://github.com/ronmi/forgejo-mcp)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
