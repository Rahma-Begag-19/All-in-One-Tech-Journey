# 📊 Grafana — Dashboards on Top of Prometheus

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd) (`monitoring/grafana/`)

---

## 1. What is Grafana?

Prometheus stores metrics and answers queries, but its UI is basic. **Grafana** turns those queries into **dashboards**: panels, graphs, gauges, tables — refreshed live.

```
Prometheus (data) ──query──► Grafana (visualization) ──► your browser :3000
```

In my stack: http://localhost:3000 (admin / admin on first start — change it!).

---

## 2. Provisioning — config as code

Instead of clicking through the UI to add a data source and import dashboards on every fresh start, Grafana **provisions** everything from files mounted at startup.

### 2.1 Data source (`grafana/provisioning/datasources/prometheus.yml`)

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    uid: prometheus              # referenced by dashboards
    type: prometheus
    access: proxy                # Grafana server queries Prometheus directly
    url: http://prometheus:9090  # compose network DNS name
    isDefault: true
    editable: true
```

One datasource, reachable by service name inside the monitoring network. `uid: prometheus` is what each dashboard panel references as `"datasource": {"uid": "prometheus"}`.

### 2.2 Dashboard provider (`grafana/provisioning/dashboards/dashboards.yml`)

```yaml
apiVersion: 1

providers:
  - name: System Monitoring
    orgId: 1
    folder: System Monitoring
    type: file
    disableDeletion: true
    editable: true
    options:
      path: /var/lib/grafana/dashboards   # where the JSON files live
```

This tells Grafana: "scan `/var/lib/grafana/dashboards` and auto-load every dashboard JSON you find there."

### 2.3 The compose mount that ties it together

```yaml
  grafana:
    image: grafana/grafana:latest
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana                      # users, settings persist
      - ./grafana/provisioning:/etc/grafana/provisioning:ro   # auto-config
      - ./grafana/dashboards:/var/lib/grafana/dashboards:ro   # auto-dashboards
    depends_on:
      - prometheus
```

Restart with a clean volume and everything — datasource + all dashboards — comes back automatically. That's infrastructure-as-code thinking applied to dashboards.

---

## 3. My dashboards

| File | Shows |
|---|---|
| `system-monitoring.json` | Host CPU, memory, disk (node-exporter) |
| `docker-containers.json` | Per-container CPU / memory / network / filesystem / limits (cAdvisor) |
| `postgresql.json` | Database connections, transactions, locks (postgres-exporter) |

### Anatomy of a panel (from `docker-containers.json`)

```json
{
  "type": "timeseries",
  "title": "CPU Usage per Container",
  "datasource": {"type": "prometheus", "uid": "prometheus"},
  "fieldConfig": {
    "defaults": {"unit": "percent", "min": 0}
  },
  "targets": [
    {
      "refId": "A",
      "expr": "sum by (name) (rate(container_cpu_usage_seconds_total{image!=\"\",name!=\"\"}[5m])) * 100",
      "legendFormat": "{{name}}"
    }
  ]
}
```

- `targets[].expr` — the PromQL query (Grafana just asks Prometheus).
- `legendFormat: "{{name}}"` — one line per container label.
- `fieldConfig.defaults.unit` — human units (percent, mebibytes, Bps).

This is why the earlier tutorials matter: **a dashboard panel is just a saved PromQL query with styling**.

---

## 4. Building a dashboard manually (when you want something new)

1. http://localhost:3000 → **Dashboards → New → New dashboard → Add visualization**.
2. Pick the **Prometheus** datasource, write a query, set the unit.
3. Save. To keep it as code: **Dashboard settings → JSON Model → copy** → save as a `.json` file in `monitoring/grafana/dashboards/` → it will auto-provision next start.
4. (Or use the "Export for provisioning" flow — share internally.)

---

## 5. Troubleshooting

| Symptom | Fix |
|---|---|
| `No data` in every panel | Datasource URL wrong — must be `http://prometheus:9090` (container name, not localhost!) |
| Dashboards don't appear on start | Check the provisioning volume mounts and file paths; Grafana logs: `docker logs monitoring-grafana` |
| Panel has data in Prometheus but not Grafana | Query works in Prometheus Graph? Same time range selected? Units/legend are cosmetic — `No data` means the query returned nothing |
| Changes to JSON not reflected | Dashboards are loaded at startup — restart Grafana; `editable: true` lets you edit in UI but those edits live in `grafana_data` |
| Forgot admin password | `docker exec monitoring-grafana grafana-cli admin reset-admin-password newpass` |

---

## 6. What I learned

- Provisioning makes Grafana **reproducible**: clone the repo, `docker compose up`, and dashboards exist.
- `localhost` inside a container means *that container* — always use compose service names for URLs between services.
- Dashboards are only as good as the PromQL behind them; learning PromQL first makes Grafana trivial.
