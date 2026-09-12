# Task 3 report

## Status
Complete. The application now mounts one of exactly two adaptive `MGRSAppShell` configurations from the signed-in user's allowed/default workspace. PIC and Tim Lapangan use isolated four-destination lists, Admin switches only between those two workspaces, and every Admin workspace switch resets the destination index to zero. Session revision, auth-change/lifecycle reload, logout, and gateway injection remain connected.

The landing surfaces were reduced to product truth: PIC shows only gateway-returned upcoming orders with loading, empty, error, and retry behavior; Tim Lapangan presents the scanner entry and logout. Legacy bento metrics, fabricated live claims, avatar assumptions, decorative painters, mixed navigation, and `AdminAppMode` were removed. Detailed destination redesign remains outside Task 3.

## Changed files
- `lib/app/app.dart`
- `lib/app/gateway.dart`
- `lib/features/auth/login_screen.dart`
- `lib/features/home/home_screen.dart`
- `lib/features/home/pic_home_screen.dart`
- `test/widget_workspace_shell_test.dart`
- `test/pic_flow_test.dart`
- Deleted `test/admin_mode_switch_test.dart` (obsolete legacy-mode contract, replaced by workspace shell coverage)
- Deleted `test/home_screen_test.dart` (obsolete invented dashboard/layout assertions, replaced by workspace/landing behavior coverage)
- `.superpowers/sdd/task-3-report.md`

## Commit
- `145afaa` — `feat: split app into role-aware workspaces`

## TDD evidence
- Initial `flutter test test/widget_workspace_shell_test.dart` — expected RED: 3 failures because the legacy shell omitted PIC Profile, all four field destinations, and the Admin workspace switcher.
- Focused field logout reproduction — expected RED: `Keluar dari akun` was absent after the landing simplification.
- Final `flutter test test/widget_workspace_shell_test.dart` — PASS; 4/4 tests passed. Covered PIC isolation, field isolation, exact two-choice Admin switcher with destination reset in both directions, injected gateway/user instances, removal of invented landing claims, and root session reload after field logout.

## Focused verification
- `flutter test test/widget_workspace_shell_test.dart` — PASS; 4/4 tests passed.
- `flutter analyze lib/app/app.dart lib/app/gateway.dart lib/features/home/home_screen.dart lib/features/home/pic_home_screen.dart lib/features/auth/login_screen.dart test/widget_workspace_shell_test.dart test/pic_flow_test.dart` — PASS; analyzed 7 items, `No issues found!`.
- `flutter test test/pic_flow_test.dart` — PASS; 11/11 remaining focused PIC/domain tests passed after removing two obsolete dashboard assertions.
- `flutter test test/widget_test.dart` — PASS; 1/1 signed-out login/validation test passed.

No formatter, standalone linter, project-wide analyzer, build, or project-wide test suite was run.

## Self-review concerns
- Detailed PIC order/invoice and field periodic/component/history screen visual redesign is intentionally deferred to Tasks 4 and 5; Task 3 only routes the existing screens.
- Camera hardware behavior was not exercised because this task changes the scanner entry/routing rather than `ScanScreen`; the injected gateway and user path into `ScanScreen` remains intact.
- The requested external code-review attempt was unavailable because the reviewer service returned HTTP 429 (`RESOURCE_EXHAUSTED`); self-review caught and fixed the initially missing Tim Lapangan logout path before the final verification and amended commit.
