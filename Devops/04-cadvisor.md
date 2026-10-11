# 🧊 cAdvisor — Container Metrics Exporter

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd) (`monitoring/docker-compose.monitoring.yml`)

---

## 1. What is cAdvisor?

**cAdvisor (Container Advisor)** is Google's open-source agent that collects **resource usage and performance statistics of running containers**: CPU, memory, network, disk — per container.

- node-exporter → tells you about the **machine**
- cAdvisor → tells you about each **container** on that machine

That's what powers the "Docker Container Monitoring" Grafana dashboard in my project.

---

## 2. The service definition

```yaml
  cadvisor:
    image: ghcr.io/google/cadvisor:latest
    container_name: monitoring-cadvisor
    privileged: true
    devices:
      - /dev/kmsg
    volumes:
      - /:/rootfs:ro            # host filesystem (read-only)
      - /var/run:/var/run:ro    # docker socket location
      - /sys:/sys:ro            # cgroup / proc info
      - /var/lib/docker:/var/lib/docker:ro   # container metadata
      - /dev/disk:/dev/disk:ro  # disk stats
    expose:
      - "8080"                   # reachable only inside the compose network
```

Why all of this?

| Mount / flag | Why |
|---|---|
| `privileged: true` + `/dev/kmsg` | cAdvisor needs kernel-level access to read cgroup stats |
| `/:/rootfs:ro` | Reads host `/proc` and `/sys` through its own namespace |
| `/var/run` | Talks to the container runtime to list containers |
| `expose` (not `ports`) | Metrics are scraped by Prometheus over the internal network only — nothing public |

No credentials, no config file — cAdvisor works out of the box. Prometheus discovers it at `cadvisor:8080` (see the Prometheus tutorial's scrape config).

---

## 3. Key metrics (and their PromQL)

All `container_*` metrics come from cAdvisor. The ones I use in my Grafana dashboard:

### CPU usage per container (percent of one core)
```promql
sum by (name) (rate(container_cpu_usage_seconds_total{image!="",name!=""}[5m])) * 100
```
`rate(...[5m])` converts the cumulative counter into per-second usage; `* 100` gives a percentage.

### Memory usage per container (MiB)
```promql
sum by (name) (container_memory_working_set_bytes{image!="",name!=""}) / 1024 / 1024
```

### Network traffic per container (bytes/sec)
```promql
sum by (name) (rate(container_network_receive_bytes_total{image!="",name!=""}[5m]))
sum by (name) (rate(container_network_transmit_bytes_total{image!="",name!=""}[5m]))
```

### Filesystem usage & memory limits
```promql
sum by (name) (container_fs_usage_bytes{image!="",name!=""}) / 1024 / 1024
max by (name) (container_spec_memory_limit_bytes{image!="",name!=""}) / 1024 / 1024
```

### ⚠️ The `{image!="",name!=""}` filter — read this!

cAdvisor also reports "pseudo-containers": cgroups for the whole host, Docker itself, systemd slices... Filtering `name!="" AND image!=""` keeps only **real** containers (only containers have an image label). Without this filter your graphs show noisy, duplicated series.

---

## 4. Quick checks

```bash
# Is cAdvisor up?
docker ps --filter name=monitoring-cadvisor

# Raw metrics (from inside the network):
docker exec monitoring-prometheus wget -qO- http://cadvisor:8080/metrics | grep container_cpu_usage_seconds_total

# In Prometheus: http://localhost:9090/graph →
container_memory_working_set_bytes{name="crm-backend-prod"}
```

---

## 5. Troubleshooting

| Symptom | Fix |
|---|---|
| No `container_*` metrics in Prometheus | Check the `cadvisor` target is `UP` at http://localhost:9090/targets |
| Metrics exist but graphs are empty/messy | You're missing the `{image!="",name!=""}` filter |
| Weird duplicated series (host totals + containers) | Same as above — those are the host-level cgroup series |
| Dashboard shows no data after container recreate | cAdvisor re-discovers containers automatically; series labels (name) update — refresh the dashboard |
| cAdvisor container keeps restarting | It needs the volume mounts; `privileged` + `/dev/kmsg` are required on most distros |

---

## 6. What I learned

- Per-container visibility comes "for free" with cAdvisor — no code changes in the app.
- Counter metrics (`*_total`) are almost always wrapped in `rate()`; gauges (`*_bytes`) are used directly.
- Always scope queries to real containers with label filters, or you'll graph the host twice.
