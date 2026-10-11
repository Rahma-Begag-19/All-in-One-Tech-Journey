# 📈 Prometheus — Metrics Collection & Alert Rules

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd) (`monitoring/` folder)

---

## 1. What is Prometheus?

Prometheus is a **time-series database + scraper**: it periodically **pulls** metrics from HTTP endpoints (`/metrics`) of your services, stores them with timestamps, lets you query them (PromQL), and can fire alerts.

```
┌──────────┐  scrape every 15s   ┌────────────────┐
│Prometheus│ ◄────────────────── │ node-exporter  │  (host CPU/RAM/disk)
│  :9090   │ ◄────────────────── │ cadvisor       │  (per-container stats)
│          │ ◄────────────────── │ postgres-export│  (DB stats)
│          │  fire alerts    ──► │ alertmanager   │  (routing → email)
└──────────┘                     └────────────────┘
       ▲
       │ query
   ┌───┴────┐
   │Grafana │  (dashboards)
   └────────┘
```

---

## 2. The configuration (`monitoring/prometheus/prometheus.yml`)

```yaml
global:
  scrape_interval: 15s            # how often to collect metrics

rule_files:
  - /etc/prometheus/alerts/*.yml  # our alert rules (see §5)

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["prometheus:9090"]

  - job_name: node-exporter
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: cadvisor
    static_configs:
      - targets: ["cadvisor:8080"]

  - job_name: postgres-exporter
    static_configs:
      - targets: ["postgres-exporter:9187"]

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093   # where to send firing alerts
```

Four sections to know:

| Section | Purpose |
|---|---|
| `global` | Defaults like `scrape_interval` |
| `scrape_configs` | Who to scrape and how often; targets are `service:port` (compose DNS names) |
| `rule_files` | Alert/recording rules loaded from mounted files |
| `alerting` | Where Prometheus sends alerts (Alertmanager) |

**Verify targets:** open http://localhost:9090/targets — every job should be green `UP`.

---

## 3. Useful PromQL queries

Run these in **Graph** at http://localhost:9090/graph:

```promql
# Is a target reachable? (1 = up, 0 = down)
up

# Host CPU usage %
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Host memory usage
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Container CPU (needs cAdvisor — see the cAdvisor tutorial)
sum by (name) (rate(container_cpu_usage_seconds_total{image!="",name!=""}[5m])) * 100

# Free disk space
node_filesystem_avail_bytes{mountpoint="/"}
```

---

## 4. Metric anatomy

A scraped metric looks like:

```
container_memory_working_set_bytes{name="crm-backend-prod",image="ghcr.io/...",id="/docker/..."} 1.234e+08
```

- `container_memory_working_set_bytes` → **metric name**
- `{name="...", image="..."}` → **labels** (dimensions you filter/group by)
- `1.234e+08` → value in bytes (~123 MB)

---

## 5. Alert rules (`monitoring/prometheus/alerts/monitoring-alerts.yml`)

```yaml
groups:
  - name: monitoring
    rules:
      - alert: MonitoringTargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Monitoring target {{ $labels.job }} is down"
          description: "Target {{ $labels.instance }} of job {{ $labels.job }} has been unreachable for more than 1 minute."

      - alert: ContainerMemoryUsageHigh
        expr: |
          sum by (name) (
            container_memory_working_set_bytes{name!="", image!=""}
          ) / (1024 * 1024) > 512
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.name }} using more than 512 MiB (threshold can be set in this file)"
          description: "Container {{ $labels.name }} has exceeded 512 MiB of memory usage for more than 5 minutes."
```

Each rule has:

| Field | Meaning |
|---|---|
| `alert` | Alert name |
| `expr` | PromQL condition — true = alert **fires** |
| `for` | Condition must hold this long before firing (anti-flapping) |
| `labels` | Metadata attached to the alert (used for routing, e.g. `severity`) |
| `annotations` | Human-readable messages; `{{ $labels.x }}` is templated per alert instance |

My two rules:
1. **`MonitoringTargetDown`** — any scrape target down for >1 min → critical. Catches crashed containers, dead exporters, network issues.
2. **`ContainerMemoryUsageHigh`** — any container above 512 MiB for 5 min → warning.

Check active rules at http://localhost:9090/alerts, and firing alerts at http://localhost:9090/alerts (filter by state) or the **Alerts** page.

---

## 6. Security & operations notes from my setup

- Prometheus binds to `127.0.0.1:9090` in the monitoring compose file — it's not exposed to the LAN. Monitoring UIs are for me, not the internet.
- Metrics storage persists in the `prometheus_data` volume.
- Exporters use `expose:` (container-to-container only) instead of `ports:` — only Prometheus needs to reach them.

---

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| Target shows `DOWN` in /targets | Check the container is up: `docker ps`; check port matches the `targets:` entry |
| Metrics look empty | Query needs label filtering — try `container_cpu_usage_seconds_total` raw first |
| Alert fires but no email | Check the `alerting` section points at `alertmanager:9093`, then see the Alertmanager tutorial |
| Changes to rules not applied | Restart Prometheus: `docker compose restart prometheus` (or send a reload via `/-/reload`) |
