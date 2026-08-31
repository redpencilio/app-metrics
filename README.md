# app-metrics

Application providing server and container metrics that can be scraped by Prometheus

## Getting started

Clone the repository and start the application using docker compose
```bash
git clone https://github.com/redpencilio/app-metrics.git
cd app-metrics
docker compose up -d
```

The services will start collecting metrics and publish them on `/metrics` and `/container-metrics`

## How-to guides
### How to configure Prometheus to scrape the metrics
This guide assumes you have a [app-server-monitor](https://github.com/redpencilio/app-server-monitor) stack with Prometheus running.

Add the following scrape jobs to `./config/prometheus/prometheus.yml`

``` yaml
scrape_configs
- job_name: "server_metrics"
  static_configs:
    - targets:
        - "metrics.my-server.org"
        - "metrics.another-server.org"
- job_name: "container_metrics"
  scrape_interval: 90s
  metrics_path: /container-metrics
  static_configs:
    - targets:
        - "metrics.my-server.org"
        - "metrics.another-server.org"
```

Restart the `prometheus` service to pick up the new scrape jobs.

### How to password protect your metrics
The metrics endpoints expose system and container details and should not be left open. There are two modes, depending on whether the metrics host shares its IP with other web apps:

- **Behind nginx-proxy (shared host):** the stack runs alongside other apps behind [app-letsencrypt](https://github.com/redpencilio/app-letsencrypt), which terminates TLS and applies basic auth. The included `docker-compose.nginx-proxy.yml` wires the dispatcher into the proxy network.
- **Standalone (dedicated IP/domain):** the host is reached directly on its own domain. The included `docker-compose.standalone.yml` adds a [Caddy](https://caddyserver.com/) service that serves HTTPS with a self-signed certificate (`tls internal`) and applies basic auth.

Both modes are opt-in overrides; default `docker compose up` runs the stack without TLS or auth.

Both modes keep the dispatcher as the single path router, so `/metrics` and `/container-metrics` are protected uniformly.

### How to password protect your metrics using nginx-proxy
This guide assumes your metric stacks is deployed on a server with [app-letsencrypt](https://github.com/redpencilio/app-letsencrypt) in front.

1. Activate the nginx-proxy override. The easiest way is to copy it to the auto-loaded override file:

   ```bash
   cp docker-compose.nginx-proxy.yml docker-compose.override.yml
   ```

   `docker compose up` applies `docker-compose.override.yml` automatically. Alternatively, pass both files explicitly:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.nginx-proxy.yml up -d
   ```

2. Set `VIRTUAL_HOST`, `LETSENCRYPT_HOST`, and `LETSENCRYPT_EMAIL` in `docker-compose.nginx-proxy.yml` to your domain and email. If your app-letsencrypt deployment uses a different network name than `letsencrypt_default`, adjust the `networks.proxy.name` accordingly.

3. Configure basic auth for that domain as explained in [the README of app-letsencrypt](https://github.com/redpencilio/app-letsencrypt).

4. Start the stack:

   ```bash
   docker compose up -d
   ```

Update the scrape job config in `./config/prometheus/prometheus.yml` by adding a `basic_auth` section

``` yaml
scrape_configs
- job_name: "server_metrics"
  basic_auth:
    username: prometheus
    password: mysecretpassword
  static_configs:
    - targets:
        - "metrics.my-server.org"
        - "metrics.another-server.org"
- job_name: "container_metrics"
  basic_auth:
    username: prometheus
    password: mysecretpassword
  scrape_interval: 90s
  metrics_path: /container-metrics
  static_configs:
    - targets:
        - "metrics.my-server.org"
        - "metrics.another-server.org"
```

Restart the `prometheus` service to pick up the changes.

### How to password protect your metrics using Caddy (standalone)
Use this mode when the metrics host has its own domain and is reached directly, without a shared nginx-proxy in front.

1. Activate the standalone override. The easiest way is to copy it to the auto-loaded override file:

   ```bash
   cp docker-compose.standalone.yml docker-compose.override.yml
   ```

   `docker compose up` applies `docker-compose.override.yml` automatically, so the Caddy service is added without modifying `docker-compose.yml`. Alternatively, pass both files explicitly:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.standalone.yml up -d
   ```

2. Generate a bcrypt hash for the Prometheus user:

   ```bash
   docker compose run --rm caddy caddy hash-password
   ```

3. Set `METRICS_DOMAIN`, `BASIC_AUTH_USER`, and `BASIC_AUTH_HASH` in `docker-compose.standalone.yml` to your domain, username, and the hash from the previous step. The Caddyfile reads these as environment variables, so it does not need to be edited.

4. Start the stack. Caddy listens on port 443 internally, published on host port 9100, and issues a self-signed certificate from its internal CA on first request — no open port 80 or HTTP-01 challenge is needed. Port 9100 must be free on the host.

   ```bash
   docker compose up -d
   ```

Then add `scheme: https`, `basic_auth`, and a TLS config that skips certificate verification (the certificate is self-signed) to the Prometheus scrape jobs:

``` yaml
scrape_configs
- job_name: "server_metrics"
  scheme: https
  basic_auth:
    username: admin
    password: mysecretpassword
  tls_config:
    insecure_skip_verify: true
  static_configs:
    - targets:
        - "metrics.my-server.org:9100"
        - "metrics.another-server.org:9100"
- job_name: "container_metrics"
  scheme: https
  basic_auth:
    username: admin
    password: mysecretpassword
  tls_config:
    insecure_skip_verify: true
  scrape_interval: 90s
  metrics_path: /container-metrics
  static_configs:
    - targets:
        - "metrics.my-server.org:9100"
        - "metrics.another-server.org:9100"
```

Restart the `prometheus` service to pick up the changes.
