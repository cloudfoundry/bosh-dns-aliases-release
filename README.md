# bosh-dns-aliases-release

This release is helpful for setting up additional DNS aliases without adding `/var/vcap/jobs/X/dns/aliases.json` to any other release.

* Documentation: [bosh.io/docs/dns](https://bosh.io/docs/dns.html)
* Slack: #bosh on <https://slack.cloudfoundry.org>

## Aliases to IP addresses

Aliases can target one or more IP addresses directly. When using IP targets, every target for that alias must specify an `ip` key; IP targets cannot be mixed with instance targets.

```yaml
aliases:
- domain: foo.example.com
  targets:
  - ip: 192.168.2.15
  - ip: 192.168.2.16
```

This generates the following entry in `aliases.json`:

```json
{
  "foo.example.com": ["192.168.2.15", "192.168.2.16"]
}
```
