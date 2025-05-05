# 📦 Odoo Module Structure Explained

Odoo modules are self-contained components that can be added to any Odoo installation to extend its functionality. Here's a breakdown of the standard module structure:

---

## 📁 Required Files and Folders

| Name              | Type     | Description |
|-------------------|----------|-------------|
| `__manifest__.py` | Required | Contains metadata like name, version, dependencies, and assets. It tells Odoo what the module is. |
| `__init__.py`     | Required | Initializes Python packages in the module. Must be in the module root and inside each Python subfolder. |
| `models/`         | Required | Holds Python classes that define database models (tables). |
| `views/`          | Required | Contains XML files defining form views, tree views, kanban, menus, etc. |
| `security/`       | Required | Defines access rights using `.csv` and `ir.model.access.csv` files. Also can contain `.xml` for record rules. |

---

## 🧩 Optional (But Useful)

| Name              | Type     | Description |
|-------------------|----------|-------------|
| `data/`           | Optional | Loads demo or default records (like stages, tags, or default configs). |
| `static/`         | Optional | Stores frontend assets: JS, CSS, SCSS, images. Use `static/src/` convention. |
| `controllers/`    | Optional | Python files to create custom website routes or REST APIs. |
| `wizards/`        | Optional | Temporary models for popup forms / multi-step operations. |
| `report/`         | Optional | Contains QWeb PDF/HTML report templates and report actions. |
| `i18n/`           | Optional | Language translation files (`.po`, `.pot`). Enables multilingual support. |
| `tests/`          | Optional | Python unit tests or YAML tests. Great for quality assurance. |
| `doc/`            | Optional | Documentation files or README images specific to the module. |
| `populate/`       | Optional | Python scripts to generate demo/test data dynamically for Odoo. |
| `migrations/`     | Optional | Database migration scripts for upgrading or downgrading module versions. |
| `demo/`           | Optional | Contains XML files with demo data used during installation to populate the database with example data. |

---

> ⚠️ A basic functional module **must include**: `__manifest__.py`, `__init__.py`, `models/`, and `views/`.

---

## 🛠️ Example Diagram
[! Odoo module structure](./images/odoo%20module%20structure.jpg)

---

Stay tuned for more on how to build clean, upgradeable, and professional Odoo modules!
