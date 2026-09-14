# Redesign Screen Matrix

Normative visual authorities: frame `y8voL5` in `Redesign UI.pen` and `DESIGN.md`. Mapping provenance: the Canvas-to-Code Matrix in `docs/superpowers/plans/2026-09-14-screen-to-code-redesign.md`.

Unresolved source: direct inspection of `C:\Users\ogi\Downloads\Redesign UI.pen` found 29 of 49 mapped canvas IDs. These 20 mapped IDs are absent from the inspected file: `t4azBZ`, `BTcsW`, `qzi8f`, `lBRgC`, `tOMM6`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw`, `DVahT`, `U9rmO`, `cL6xW`, `sVFCA`, `c5fyaG`, `wda7C`, `Xizur`, `Ltkxp`, `cTy8K`, `uz7xq`, and `gKrU1`. Rows retain the plan's IDs without replacement, but none of these IDs can receive `Verified: yes` until the design file or version is reconciled.

`required` means the state is part of acceptance even when the plan does not map a dedicated canvas ID. `n/a` marks a state that does not apply to a non-list screen. A canvas ID in a state column is the mapped visual reference. No row is implemented or verified at the start of this ledger.

| Canvas ID | Design name | Flutter owner | Loaded | Loading | Empty | Error | Search empty | Implemented | Verified |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `y8voL5` | Foundations | `lib/app/app_theme.dart`, `lib/design_system/*` | n/a | n/a | n/a | n/a | n/a | no | no |
| `FDInN` | Profil Admin | profile sheet in `home_screen.dart` and `pic_home_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `U5fSK` | Beranda operasional | `lib/features/home/home_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `XAOVW` | Daftar order | `lib/features/schedule/upcoming_orders_screen.dart` | yes | required | `zfLV8` | required | n/a | no | no |
| `G2Duhu` | Detail order & alokasi | `order_detail_screen.dart`, `unit_allocation_card.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `NxK5V`, `t4azBZ`, `BTcsW`, `qzi8f` | Pilih komponen and state variants | `lib/features/schedule/component_picker_sheet.dart` | yes | required | required | required | required | no | no |
| `Cs0Cf` | Konfirmasi order | confirmation UI in `order_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `ZD3Ks` | Katalog | `lib/features/components/asset_catalog_screen.dart` | yes | required | required | required | `DVahT` | no | no |
| `wpHDh` | Detail komponen | `lib/features/components/component_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `BEhNG`, `lBRgC`, `tOMM6` | Perbarui kondisi and form states | `lib/features/maintenance/checking_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `F5r3W3`, `BSfSy` | Pemeriksaan berhasil and laporan servis berhasil | success sheet in `checking_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `Nb5Mm` | Catat servis | `CheckingScreen(service: true)` | n/a | n/a | n/a | n/a | n/a | no | no |
| `P0DHyS` | Pusat tindakan | `lib/features/maintenance/action_center_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `DbVfe`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw` | Scanner barcode and scanner states | `lib/features/scan/scan_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `Z3jInt`, `DVahT` | Riwayat komponen and list search states | `lib/features/history/history_screen.dart` | yes | required | required | required | `DVahT` | no | no |
| `yXaDP` | Detail riwayat | `lib/features/history/history_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `U9rmO` | Login | `lib/features/auth/login_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `cL6xW` | Buat order | `lib/features/schedule/create_order_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `sVFCA` | Batalkan order | cancellation dialog in `upcoming_orders_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `c5fyaG` | Scan alokasi | allocation scan mode in `unit_allocation_card.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `Zesyn` | PIC Beranda | `lib/features/home/pic_home_screen.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `zfLV8` | Order kosong | empty state in `upcoming_orders_screen.dart` | n/a | n/a | yes | n/a | n/a | no | no |
| `Am5S7`, `wda7C`, `Xizur`, `Ltkxp` | PIC 02 · Daftar invoice | `InvoiceListScreen` | yes | `Xizur` | `wda7C` | `Ltkxp` | `DVahT` | no | no |
| `I6BN3` | Pembayaran | `lib/features/invoices/quick_payment_dialog.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `Tqj7E`, `xhUdK` | Detail and edit invoice | `lib/features/invoices/invoice_builder_dialog.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `i1muR`, `R5HNus` | Ekspor PDF and success | `lib/features/invoices/pdf/invoice_pdf_dialogs.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
| `lufpi`, `LmGKc` | Invoice from order and manual reimbursement | `create_invoice_dialog.dart`, invoice builder source mode | n/a | n/a | n/a | n/a | n/a | no | no |
| `Qb9H5`, `UQQgU` | Invoice payment-status card variants | invoice card variants by `InvoicePaymentStatus` | n/a | n/a | n/a | n/a | n/a | no | no |
| `cTy8K` | Hapus invoice | destructive confirmation from invoice detail | n/a | n/a | n/a | n/a | n/a | no | no |
| `uz7xq`, `gKrU1` | Session overlay | session overlay in `lib/app/app.dart` | n/a | n/a | n/a | n/a | n/a | no | no |
