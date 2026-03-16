# app-metrics

Application providing server and container metrics that can be scraped by Prometheus

## Getting started

Clone the repository and start the application using docker compose
```bash
git clone https://github.com/redpencilio/app-metrics.git
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

### How to password protect your metrics using nginx-proxy
This guide assumes your metric stacks is deployed on a server with [app-letsencrypt](https://github.com/redpencilio/app-letsencrypt) in front. Configure basic auth for the domain your metrics stack is deployed on as explained in [the README of app-letsencrypt](https://github.com/redpencilio/app-letsencrypt).

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
