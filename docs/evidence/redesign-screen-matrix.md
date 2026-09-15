# Redesign Screen Matrix

Source of truth: `Redesign UI.pen`, foundation `y8voL5`, and `DESIGN.md`. Mapping provenance: the Canvas-to-Code Matrix in `docs/superpowers/plans/2026-09-14-screen-to-code-redesign.md`.

## Source Reconciliation & Scope Status

Direct inspection of `C:\Users\ogi\Downloads\Redesign UI.pen` confirmed 29 of 49 mapped canvas IDs.
The following 20 mapped IDs are absent from the inspected design file:
`t4azBZ`, `BTcsW`, `qzi8f`, `lBRgC`, `tOMM6`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw`, `DVahT`, `U9rmO`, `cL6xW`, `sVFCA`, `c5fyaG`, `wda7C`, `Xizur`, `Ltkxp`, `cTy8K`, `uz7xq`, and `gKrU1`.

Per Task 12 acceptance policy:
- `Implemented=yes` is granted only where Flutter owner code exists and automated tests pass.
- `Verified=yes` is granted only where visual comparison to an existing canvas frame in `Redesign UI.pen` and golden/device evidence are confirmed.
- Any row referencing absent canvas IDs retains `Verified=no` with the specific missing canvas IDs recorded.

## Screen Matrix Ledger

| Canvas ID | Design name | Flutter owner | Loaded | Loading | Empty | Error | Search empty | Implemented | Verified | Notes / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `y8voL5` | Foundations | `lib/app/app_theme.dart`, `lib/design_system/*` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden suite, `DESIGN.md` tokens, Inter font |
| `FDInN` | Profil Admin | profile sheet in `home_screen.dart` and `pic_home_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | `admin_mode_switch_test.dart`, `app_flow_test.dart` Flow 2 |
| `U5fSK` | Beranda operasional | `lib/features/home/home_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden `service_home.png`, emulator Flow 1 |
| `XAOVW` | Daftar order | `lib/features/schedule/upcoming_orders_screen.dart` | yes | required | `zfLV8` | required | n/a | yes | yes | Golden `order_list.png`, `order_visual_states_test.dart` |
| `G2Duhu` | Detail order & alokasi | `order_detail_screen.dart`, `unit_allocation_card.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden `order_detail.png`, emulator Flow 2 |
| `NxK5V`, `t4azBZ`, `BTcsW`, `qzi8f` | Pilih komponen and state variants | `lib/features/schedule/component_picker_sheet.dart` | yes | required | required | required | required | yes | no | Implemented & golden `component_picker.png` PASS; Verified=no due to missing source canvas `t4azBZ`, `BTcsW`, `qzi8f` |
| `Cs0Cf` | Konfirmasi order | confirmation UI in `order_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against canvas `Cs0Cf`, `order_detail_screen_test.dart` |
| `ZD3Ks` | Katalog | `lib/features/components/asset_catalog_screen.dart` | yes | required | required | required | `DVahT` | yes | yes | Golden `catalog.png`, emulator Flow 1 |
| `wpHDh` | Detail komponen | `lib/features/components/component_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden `component_detail.png`, emulator Flow 1 |
| `BEhNG`, `lBRgC`, `tOMM6` | Perbarui kondisi and form states | `lib/features/maintenance/checking_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & golden `checking.png` PASS; Verified=no due to missing source canvas `lBRgC`, `tOMM6` |
| `F5r3W3`, `BSfSy` | Pemeriksaan berhasil and laporan servis berhasil | success sheet in `checking_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `F5r3W3`, `BSfSy`, emulator Flow 1 |
| `Nb5Mm` | Catat servis | `CheckingScreen(service: true)` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden `service_form.png`, `checking_visual_states_test.dart` |
| `P0DHyS` | Pusat tindakan | `lib/features/maintenance/action_center_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `P0DHyS`, `flow_screens_test.dart` |
| `DbVfe`, `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw` | Scanner barcode and scanner states | `lib/features/scan/scan_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & golden `scanner_fallback.png` PASS; Verified=no due to missing source canvas `PHWAe`, `V4woXN`, `w0WWMY`, `N3YDPw` |
| `Z3jInt`, `DVahT` | Riwayat komponen and list search states | `lib/features/history/history_screen.dart` | yes | required | required | required | `DVahT` | yes | no | Implemented & tested; Verified=no due to missing source canvas `DVahT` |
| `yXaDP` | Detail riwayat | `lib/features/history/history_detail_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `yXaDP`, `flow_screens_test.dart` |
| `U9rmO` | Login | `lib/features/auth/login_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & golden `login.png` PASS; Verified=no due to missing source canvas `U9rmO` |
| `cL6xW` | Buat order | `lib/features/schedule/create_order_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & tested; Verified=no due to missing source canvas `cL6xW` |
| `sVFCA` | Batalkan order | cancellation dialog in `upcoming_orders_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & tested; Verified=no due to missing source canvas `sVFCA` |
| `c5fyaG` | Scan alokasi | allocation scan mode in `unit_allocation_card.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & tested; Verified=no due to missing source canvas `c5fyaG` |
| `Zesyn` | PIC Beranda | `lib/features/home/pic_home_screen.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Golden `pic_home.png`, emulator Flow 2 |
| `zfLV8` | Order kosong | empty state in `upcoming_orders_screen.dart` | n/a | n/a | yes | n/a | n/a | yes | yes | Visual match against `zfLV8`, `order_visual_states_test.dart` |
| `Am5S7`, `wda7C`, `Xizur`, `Ltkxp` | PIC 02 · Daftar invoice | `InvoiceListScreen` | yes | `Xizur` | `wda7C` | `Ltkxp` | `DVahT` | yes | no | Implemented & goldens `invoice_list.png`, `invoice_empty.png`, `invoice_failure.png` PASS; Verified=no due to missing source canvas `wda7C`, `Xizur`, `Ltkxp` |
| `I6BN3` | Pembayaran | `lib/features/invoices/quick_payment_dialog.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `I6BN3`, `invoice_visual_states_test.dart` |
| `Tqj7E`, `xhUdK` | Detail and edit invoice | `lib/features/invoices/invoice_builder_dialog.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `Tqj7E`, `xhUdK`, `invoice_visual_states_test.dart` |
| `i1muR`, `R5HNus` | Ekspor PDF and success | `lib/features/invoices/pdf/invoice_pdf_dialogs.dart` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `i1muR`, `R5HNus`, `invoice_pdf_dialogs_test.dart` |
| `lufpi`, `LmGKc` | Invoice from order and manual reimbursement | `create_invoice_dialog.dart`, invoice builder source mode | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `lufpi`, `LmGKc`, `invoice_visual_states_test.dart` |
| `Qb9H5`, `UQQgU` | Invoice payment-status card variants | invoice card variants by `InvoicePaymentStatus` | n/a | n/a | n/a | n/a | n/a | yes | yes | Visual match against `Qb9H5`, `UQQgU`, `invoice_visual_states_test.dart` |
| `cTy8K` | Hapus invoice | destructive confirmation from invoice detail | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & tested; Verified=no due to missing source canvas `cTy8K` |
| `uz7xq`, `gKrU1` | Session overlay | session overlay in `lib/app/app.dart` | n/a | n/a | n/a | n/a | n/a | yes | no | Implemented & emulator Flow 4 PASS; Verified=no due to missing source canvas `uz7xq`, `gKrU1` |
