# Inventory Management System (MySQL + Web UI)

## Folder structure
```
inventory_management_system/
 README.md
 app/index.html              StockPilot web app (open in any browser)
 database/
   inventory_full.sql        ONE-FILE import: schema + data + views, procedures, trigger + reports
   01_schema.sql ... 07_advanced.sql   individual parts (queries, joins, subqueries, reports, advanced)
 docs/
   PROJECT_DOCUMENTATION.md  problem statement, objectives, modules, ER diagram
   project_website.html      navigable documentation site with SQL and ER diagram
```

## Run the database (MySQL 8.0.16+ required for CHECK constraints)
**Command line**
```
mysql -u root -p < database/inventory_full.sql
```
**MySQL Workbench:** File > Open SQL Script > `database/inventory_full.sql` > run (lightning icon).

For step-by-step marking, run in order: `01_schema.sql`, `02_sample_data.sql`, `07_advanced.sql`, then `03` to `06`.
Run the trigger/procedure script only after the sample data is loaded, otherwise stock is reduced twice.

## Run the web app
Double-click `app/index.html`. It is self-contained (no install) and keeps its data in the browser, so it is a UI demo of the same model, not connected to MySQL. Use "Reset demo data" in the sidebar to restore the sample records.

## Submission checklist
Documentation (docs/) - ER diagram - database script (database/) - queries and reports with outputs - screenshots of query runs (take these yourself from MySQL).
