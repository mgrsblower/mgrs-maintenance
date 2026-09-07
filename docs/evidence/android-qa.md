# Android QA evidence

Date: 7 September 2026  
Device: `mgrs_phase2_x86_qa`, Android emulator, 1080 x 1920  
Package: `com.mgrs.mgrs_maintenance`

## Observed workflow

`flutter drive --driver integration_test/driver.dart --target integration_test/app_flow_test.dart -d emulator-5554` completed successfully. The test drove the Flutter surface through:

1. authenticated three-tab shell using an injected QA gateway;
2. manual sticker lookup for a Kepala component;
3. detail display without a write;
4. reviewed manual condition change from Rusak Ringan/Tidak to OK/Ya;
5. service form with problem, action, result, review, and save;
6. monthly task list for the fourth-weekend period;
7. combined manual/service history, before/after detail, and append-only correction entry point.

The first device run exposed an invalid asynchronous `setState` callback in component detail refresh. The callback and the identical history-detail pattern were corrected before the passing run.

## Visual artifacts

- `screenshots/maintenance-login.png`: cold start of the real app build using the locally configured Supabase URL and publishable key. No credentials were entered and no remote mutation occurred.
- `screenshots/maintenance-history-detail.png`: the QA flow's recorded before/after history.
- `screenshots/maintenance-correction-action.png`: the append-only correction action after scrolling the real Android surface.

## Limits

The QA gateway is synthetic and exists only under `integration_test/`. This proves Android navigation, validation, form state, and rendered behavior; it is not proof of deployed Supabase RPCs or authentication. Camera permission and a physical barcode were not tested because no physical device is attached. The live database received read-only metadata queries only.

The final development APK was rebuilt from the normal `lib/main.dart` target with the ignored local configuration file. It is 195,761,884 bytes with SHA-256 `ed4c5de25f965a7f57cd557dc6649aea335f4fb33691625b8b1aff27579ec9a7`. It uses debug signing and is not a production release artifact.
