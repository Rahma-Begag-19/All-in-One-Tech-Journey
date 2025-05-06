# 🧠 Understanding Odoo's `res.*` Models

A complete reference to the core `res.*` models in Odoo — how they relate to each other, their most used fields, and how they power many parts of the system.

---

## 📚 About This Guide

In this post, we explore the most commonly used `res.*` models in Odoo and how they relate to each other. This is not an exhaustive documentation but rather a **developer-friendly reference** focusing on what you’ll actually deal with when building real modules.

---

## 🧩 Key Models Covered

We'll talk about the following models:

* `res.partner`
* `res.users`
* `res.company`
* `res.country`
* `res.lang`
* `res.currency`
* `res.bank`
* `res.groups`
* `res.config.settings`
* `res.branch` *(community)*

---

## 🧬 Relationships Between Them

* `res.users` inherits and extends `res.partner`
* `res.company` relates to `res.partner` through `partner_id`
* `res.users` belongs to one `res.company` (multi-company support)
* `res.partner` has country and language fields linked to `res.country` and `res.lang`
* `res.users` are assigned to `res.groups`
* `res.config.settings` is a transient model that interacts with permanent settings like company, language, currency, etc.

---

## 📦 Model Summaries with Common Fields

### 🔹 res.partner

* Represents contacts (customers, vendors, companies, individuals)
* Common Fields:

  * `name`, `email`, `phone`
  * `is_company`, `parent_id`, `child_ids`
  * `type` (contact/invoice/delivery/etc.)
  * `company_id`, `user_id`
  * `lang`, `country_id`, `state_id`

### 🔹 res.users

* Represents actual system users
* Extends `res.partner`
* Common Fields:

  * `login`, `password`
  * `groups_id`, `active`, `signature`
  * `company_id`, `company_ids`

### 🔹 res.company

* Represents each legal entity in multi-company setups
* Common Fields:

  * `name`, `partner_id`
  * `currency_id`, `country_id`
  * `logo`, `email`, `phone`

### 🔹 res.country / res.country.state

* Holds countries and subdivisions
* Used for partner addresses

### 🔹 res.lang

* Available languages in the system
* Used in partner or user preferences

### 🔹 res.currency

* Used for multi-currency handling
* Linked to company, transactions

### 🔹 res.groups

* Used to manage user access rights and permissions
* Users are assigned to groups

### 🔹 res.config.settings

* Transient model for system settings UI
* Saves values into other permanent models (like `res.company` or system parameters)

### 🔹 res.bank

* Bank directory
* Linked in payment methods, partner bank accounts

### 🔹 res.branch *(Community Only)*

* Used in multi-branch architecture (like multi-company)
* Not official in standard Odoo but widely used in larger systems

---

> This file is part of my ongoing journey to master Odoo — and share everything I learn. Contributions and feedback welcome 💬
