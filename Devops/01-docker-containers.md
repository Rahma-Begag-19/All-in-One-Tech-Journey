# 🐳 Docker & Docker Compose — From Zero to a Multi-Container App

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd)
> A full-stack CRM (FastAPI + PostgreSQL + Nginx frontend), fully containerized.

---

## 1. What problem does Docker solve?

Before Docker, running an app meant: *"install Python 3.12, then PostgreSQL 16, then Nginx, then configure all the versions to match my machine..."* — and it broke on every other machine.

Docker packages an app **with everything it needs** (runtime, dependencies, code) into an **image**, which runs the same everywhere as a **container**.

| Concept | What it is |
| --- | --- |
| **Image** | A read-only template (like a recipe + ingredients) |
| **Container** | A running instance of an image (the actual meal) |
| **Dockerfile** | Text file with instructions to build an image |
| **Docker Compose** | YAML file to run **multiple** containers together |

---

## 2. The Dockerfiles

### 2.1 Backend Dockerfile (`backend/Dockerfile`)

```dockerfile
FROM python:3.12-slim          # 1. Start from a minimal Python image

WORKDIR /app                   # 2. Create and enter /app inside the image

COPY requirements.txt .        # 3. Copy ONLY the dependency list first
RUN pip install --no-cache-dir -r requirements.txt   # 4. Install deps (cached layer!)

COPY app ./app                 # 5. Copy the actual code
COPY alembic ./alembic
COPY alembic.ini .
COPY seed.py .
COPY start.sh .

RUN chmod +x start.sh          # 6. Make the startup script executable

CMD ["./start.sh"]             # 7. What runs when the container starts
```

**💡 Key lesson — layer caching:** Docker caches each step. If we copied the code *before* installing dependencies, every code change would re-run `pip install` (slow!). By copying `requirements.txt` first, dependencies install once and get cached; code changes only rebuild from step 5. **Always copy dependency manifests before source code.**

`start.sh` shows the container's job at startup:

```bash
#!/bin/sh
echo "Running database migrations..."
alembic upgrade head           # apply DB migrations automatically

echo "Starting FastAPI..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
```

> `exec` replaces the shell process with uvicorn, so the app receives shutdown signals (SIGTERM) correctly.

### 2.2 Frontend Dockerfile (`frontend/dockerfile`)

```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
```

The frontend is plain HTML — Nginx serves it directly. That's the whole file. Sometimes the simplest Dockerfile is the right one.

---

## 3. Development stack (`docker-compose.yml`)

```yaml
services:
  db:
    image: postgres:16
    container_name: crm-postgres-final
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data   # data survives container deletion
    ports:
      - "5433:5432"    # host:container — host 5433 avoids conflicts with local Postgres

  backend:
    build:
      context: ./backend           # build from our Dockerfile
    container_name: crm-backend-final
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      #                        ↑ inside the compose network, services talk by NAME: "db"
    depends_on:
      - db
    ports:
      - "8080:8000"    # FastAPI runs on 8000 inside, reachable on 8080 outside

  frontend:
    build:
      context: ./frontend
    container_name: crm-frontend-final
    ports:
      - "5500:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Things to understand deeply

1. **Service discovery by name** — inside the compose network, the database host is just `db`. That's why `DATABASE_URL` uses `@db:5432`. No IPs needed.
2. **`volumes`** — without `postgres_data:/var/lib/postgresql/data`, **every `docker compose down` would wipe your database**. Named volumes persist data independently of container lifecycle.
3. **`ports` mapping** — `"8080:8000"` = publish container port 8000 on host port 8080. (Host side must be free — I used 5433 for Postgres because a local PostgreSQL was already on 5432.)
4. **`depends_on`** — controls *startup order*, not readiness. In dev it's fine; in prod we need more (see below).
5. **`${VARS}`** — values come from a `.env` file (never commit it!). Copy `.env.example` → `.env` and fill it in.

---

## 4. Production stack (`docker-compose.prod.yml`)

Differences from dev:

```yaml
  backend:
    image: ghcr.io/rahma-begag-19/fastapi-docker-cicd/backend:latest   # pull, don't build
    depends_on:
      db:
        condition: service_healthy      # wait until DB is ACTUALLY ready
```

| Dev | Prod |
| --- | --- |
| `build:` from local Dockerfile | `image:` pulled from GHCR (built by CI) |
| No healthcheck on DB | `healthcheck` with `pg_isready` |
| `depends_on: - db` (order only) | `condition: service_healthy` (real readiness) |
| Volume `postgres_data` | `postgres_data_prod` (separate data!) |

The database healthcheck:

```yaml
healthcheck:
  test: [ "CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}" ]
  interval: 5s
  timeout: 5s
  retries: 5
```

**Why it matters:** without it, the backend can start before Postgres accepts connections and crash on its first query. `pg_isready` asks Postgres "are you up?", and `service_healthy` makes the backend wait for a *healthy* state, not just a *started* one.

---

## 5. Essential commands cheat sheet

```bash
# Build & start everything
docker compose up -d --build

# See logs (follow mode)
docker compose logs -f backend

# Restart one service
docker compose restart backend

# Stop everything (keeps volumes)
docker compose down

# Stop AND delete data volumes (⚠️ wipes the database!)
docker compose down -v

# Validate the compose file renders correctly
docker compose config

# Inspect resource usage
docker stats

# Get a shell inside a container
docker exec -it crm-backend-final sh
```

Bonus — my [`docker-inventory.sh`](https://github.com/Rahma-Begag-19/fastapi-docker-cicd/blob/main/monitoring/scripts/docker-inventory.sh) script prints a full report of containers, images, volumes and disk usage (`docker system df -v`). Great for audits.

---

## 6. Troubleshooting (things I actually hit)

| Symptom | Cause | Fix |
| --- | --- | --- |
| `port is already allocated` | Host port taken (5432, 8080...) | Change the **host** side of the mapping, e.g. `"5433:5432"` |
| Backend crashes on start | DB not ready | `depends_on` + `condition: service_healthy` |
| DB data gone after `down` | Missing named volume | Declare a volume under `volumes:` and mount it |
| `variable is not set` | `.env` missing or incomplete | Create it from `.env.example` |
| Rebuild is super slow every time | `COPY . .` before `pip install` | Copy dependency manifest first (see §2.1) |
| Changes not reflected | Old image cached | `docker compose up -d --build` |

---

## 7. What I learned

- Dockerfiles are about **layer ordering** — cache-friendly builds save minutes per iteration.
- Compose gives you **networking, persistence and startup order** for free via YAML.
- Dev and prod should be **different compose files**, not one file with hacks.
- Secrets always live in `.env`, never in the repo.