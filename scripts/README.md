# Backup and restore

Create a custom-format database backup from PowerShell:

```powershell
.\scripts\backup-database.ps1
```

Backup files are written to `backups\`; keep that folder private and off Git because it contains employee data.

Test a backup by restoring it to a new, isolated database:

```powershell
.\scripts\restore-database.ps1 -BackupFile .\backups\hris-YYYYMMDD-HHmmss.dump -DatabaseName hris_restore_test
```

The restore script refuses to overwrite an existing database. Validate the restored data, then remove only the explicitly named test database when finished. Production recovery procedures should additionally define encrypted off-device storage, retention, and access controls.
