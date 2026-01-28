# PostgreSQL Commands: Show Databases, Schemas, and Tables

This document lists commonly used **PostgreSQL (`psql`) commands** to inspect databases, schemas, tables, and related objects.

---

## List All Databases

```sql
\l
```

or

```sql
\list
```

Displays database name, owner, encoding, collation, and access privileges.

---

## Connect to a Database

```sql
\c database_name
```

Example:
```sql
\c mydb
```

---

## List All Schemas in the Current Database

```sql
\dn
```

Common schemas:
- `public`
- `information_schema`
- `pg_catalog`

---

## List Tables

### Tables in the Current Schema
```sql
\dt
```

### Tables in All Schemas
```sql
\dt *.*
```

### Tables in a Specific Schema
```sql
\dt schema_name.*
```

Example:
```sql
\dt public.*
```

---

## Describe Table Structure

```sql
\d table_name
```

Detailed view (includes size, storage, etc.):
```sql
\d+ table_name
```

---

## List Other Database Objects

### Views
```sql
\dv
```

### Indexes
```sql
\di
```

### Sequences
```sql
\ds
```

### Functions
```sql
\df
```

---

## SQL-Based Alternatives (Non-psql Environments)

### List All Tables Using SQL
```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;
```

---

## Quick Cheat Sheet

```sql
\l        -- list databases
\c db     -- connect to database
\dn       -- list schemas
\dt       -- list tables
\d table  -- describe table
```

---

## Notes

- Commands starting with `\` are **psql meta-commands**
- These do **not work** inside application code or JDBC
- Use SQL alternatives when running queries via tools or frameworks
