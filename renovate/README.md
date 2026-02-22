# Renovate Configuration

This directory contains the Renovate bot configuration file.

## config.js

This is the global Renovate configuration that applies to all repositories the bot scans.

The configuration reads `RENOVATE_ENDPOINT` from the environment variable set in docker-compose.yml. If this variable is not set, Renovate will fail to start, making misconfiguration obvious.

**Important**: After changing this file, restart the Renovate service:
```bash
docker compose restart renovate
```

## Customizing Renovate

Edit `config.js` to customize Renovate's behavior:

- **autodiscover**: Set to `false` and add `repositories: ['owner/repo1', 'owner/repo2']` to scan specific repos only
- **schedule**: Add cron-like schedule (e.g., `schedule: ['after 10pm', 'before 5am']`)
- **packageRules**: Group updates, set automerge rules, etc.
- **prHourlyLimit** / **prConcurrentLimit**: Control rate of PR creation

See the [Renovate documentation](https://docs.renovatebot.com/configuration-options/) for all available options.

## Per-Repository Configuration

Renovate will create an onboarding PR in each repository with a `renovate.json` file. Edit that file to customize Renovate's behavior for specific repositories.

Example `renovate.json`:
```json
{
  "extends": ["config:base"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    }
  ],
  "schedule": ["every weekend"]
}
```
