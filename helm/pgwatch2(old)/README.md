# Documentation


Key | Default value | Description
---|---|---
storage                   | influx                 | influx or postgres; Defines backend for storing data
postgres_storage.database | pgwatch2_metrics       | in case if storage is set to postgres, defines database name
metrics_preset            |                        |
metrics_preset.name       | remotedba              | name of the default metrics_preset
metrics_preset.description| Metrics used for monitoring of Remote-DBA Databases | Metrics preset description
metrics_preset.metrics    | '{"kpi": 120, "wal": 60, "locks": 60, "db_size": 300, "archiver": 60, "backends": 60, "bgwriter": 60, "cpu_load": 60, "db_stats": 60, "settings": 7200, "wal_size": 300, "locks_mode": 60, "index_stats": 900, "replication": 120, "sproc_stats": 180, "table_stats": 300, "wal_receiver": 120, "change_events": 300, "table_io_stats": 600, "sequence_health": 3600, "replication_slots": 120}' | Metrics
