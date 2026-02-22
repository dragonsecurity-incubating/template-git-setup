module.exports = {
  platform: 'forgejo',
  // RENOVATE_ENDPOINT must be set in docker-compose.yml to your Forgejo instance URL
  endpoint: process.env.RENOVATE_ENDPOINT,
  autodiscover: true,
  // optional: helps on first run
  onboarding: true,
  // optional: reduce noise
  prHourlyLimit: 2,
  prConcurrentLimit: 10,
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
