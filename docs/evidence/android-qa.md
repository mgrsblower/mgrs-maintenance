# Android QA Evidence & Verification Log

Date: 15 September 2026  
Device: `mgrs_phase2_x86_qa`, Android emulator (`emulator-5554`), Android API 37 (x86_64), 1080 x 1920  
Package: `com.mgrs.mgrs_maintenance`  
Branch: `RedesignUI`

---

## 1. Integration Test Execution (Android Emulator API 37)

Execution command:
```bash
flutter drive --driver integration_test/driver.dart --target integration_test/app_flow_test.dart -d emulator-5554
```
Result: **100% PASS (4/4 Flows Completed Successfully)**.

### Verified Critical Flows
1. **Flow 1: Service Shell & Tab Navigation**
   - Authenticated technician navigation shell.
   - Seamless switching across tabs (Beranda, Aset, Servis) and floating scanner action.
2. **Flow 2: PIC Mode Switch & Bottom Sheet Navigation**
   - User profile bottom sheet trigger.
   - Role toggle between PIC and Teknisi.
   - Dynamically adapts bottom navigation items (`picNavItems`) and specialized PIC dashboard widgets.
3. **Flow 3: Invoice Error Retry & Empty State Handling**
   - Handles network/server RPC simulation failure with retry UI.
   - Graceful fallback to empty state representation.
4. **Flow 4: Session Expiry Handling**
   - Detects session timeout/token expiration.
   - Redirects to login prompt cleanly without app crashes or memory leaks.

---

## 2. Responsive & Accessibility Matrix Verification

Automated suite: `test/responsive_accessibility_test.dart` (36 tests, 100% PASS).

### Screen Width Breakpoints
- **320px**: Verified without layout overflow (`RenderFlex` 0px overflow). Greeting row on `PicHomeScreen` uses `Flexible` with `MainAxisSize.min` to fit compact width.
- **360px**: Standard Android baseline, renders cleanly.
- **390px**: Modern mobile portrait standard, full card padding preserved.
- **430px**: Large device viewport, constrained content max-width applied.

### Text Scale Factors (A11y)
- **100% (1.0x)**: Standard system font scaling.
- **150% (1.5x)**: Large font scaling for readability, labels and multi-line headers wrapped properly.
- **200% (2.0x)**: Extra large accessibility text scaling, critical form fields, action buttons, and bottom navigation remain fully usable without clipping.

### Keyboard & Semantic Labels
- **Keyboard viewInsets**: `CheckingScreen` and forms properly adjust bottom padding when virtual keyboard emerges (`viewInsets.bottom >= 300`).
- **Semantic Labels**: TalkBack and accessibility labels verified for `Profil pengguna, <name>`, `Lihat semua`, and `Buka pemindai kode`.

---

## 3. Hardware Gaps & Limitations

1. **Camera Sensor & Optical QR Scanning**:
   - Tested using mock/synthetic manual code fallback input on the emulator.
   - No physical optical camera sensor was available during emulator test runs; camera hardware permissions and live video stream frame processing must be re-validated on a physical device.
2. **Architecture & Device Profile**:
   - Verification was performed on an `x86_64` Android emulator (`emulator-5554`), not on physical ARM64 hardware.
   - Performance characteristics, hardware graphics acceleration (Vulkan/Skia), and battery impact were not benchmarked on physical hardware.
3. **Gateway Backend**:
   - Tested with synthetic mock gateway (`MaintenanceGateway` in-memory / local test doubles).
   - Production Supabase credentials, remote RPC transactions, and edge functions are decoupled and untouched.

---

## 4. Visual & Golden Test Coverage

- 14 Golden image baselines in `test/golden/goldens/` verified with **100% PASS** via `test/golden/redesign_golden_test.dart`.
- All screens run with deterministic clock via `nowProvider`.

