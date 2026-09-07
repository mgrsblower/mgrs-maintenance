# MGRS-Maintenance

Aplikasi terpisah untuk pemeriksaan dan servis Kepala, Batang, dan Tabung dengan database MGRS bersama.

- [PRD](PRD.md)
- [Implementation plan](docs/superpowers/plans/2026-09-06-mgrs-maintenance-implementation.md)
- [Implementation ledger](docs/evidence/implementation-ledger.md)
- [Android QA evidence](docs/evidence/android-qa.md)
- [Database compatibility](docs/decisions/002-shared-database.md)

MVP lokal Android sudah diimplementasikan. Deployment database bersama, aktivasi jadwal, akun QA nyata, signing release, dan uji kamera fisik tetap mengikuti gate pada implementation ledger. Jangan apply baseline Supabase lokal ke database existing. Metadata live yang tersimpan berisi schema/policy dan agregat, tanpa token atau data akun.

Jalankan aplikasi dengan file lokal berisi `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, dan `APP_ENV`:

```bash
flutter run -d <device> --dart-define-from-file=config/development.local.json
```

Verifikasi lokal: `flutter analyze`, `flutter test`, dan `node tools/db-harness/verify-baseline.mjs --maintenance`. Harness memakai PostgreSQL lokal dengan auth shim untuk uji SQL, bukan bukti autentikasi Supabase end-to-end.
