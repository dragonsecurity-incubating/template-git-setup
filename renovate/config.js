module.exports = {
  platform: 'forgejo',
  endpoint: 'https://git.example.com/api/v1',
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
