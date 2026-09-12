# MGRS Porcelain Service Ledger Design

## Decision

Replace the current mixed visual implementation with **Porcelain Service Ledger**, an Android-native operational design system adapted from the copied Glow reference. Preserve product workflows, navigation, functionality, Indonesian copy, role permissions, and data behavior. Copy changes are limited to labels or errors that are demonstrably unclear.

The copied `DESIGN.md`, `tokens.json`, `variables.css`, and `theme.css` are source references, not runtime contracts. Their web marketing, crypto, Solana, iPhone mockup, hero, and conversion patterns do not enter the Android product. The shipped Flutter implementation becomes visual ground truth; `DESIGN.md` is rewritten from that result at finish.

## Alternatives Considered

1. **Porcelain Service Ledger — selected.** Bright porcelain canvas, white work surfaces, ink structure, and one magenta primary action. Best readability for workshop, warehouse, and outdoor use.
2. **Flight Case Console.** Dark equipment-console surfaces with magenta active current. Distinctive but weaker in sunlight and too visually heavy across long forms.
3. **Signal Label System.** Large magenta regions and inventory-label badges. Memorable but creates unnecessary competition between brand color and operational status colors.

## Visual Foundation

### Color roles

- Canvas: Porcelain `#F4F5F6`.
- Surface: Pure White `#FFFFFF`.
- Primary text and structural controls: Ink `#131517`.
- Secondary text: Stone `#737577`.
- Borders and disabled dividers: Mist `#B3B5B7` with lighter tonal variants derived in the Flutter theme.
- Brand action: Voltage Magenta `#CC62D5`.
- Magenta marks the single visually dominant brand action in a screen-level viewport. When that action is visible, navigation and selection states use Ink tonal treatment; when no primary action is present, one selected control may use magenta. Magenta never encodes success, warning, danger, payment, or component condition.
- Semantic colors remain distinct: green for success, amber for warning or partial state, and red for errors or destructive actions. Every semantic state includes a text label or icon; color is never the sole signal.
- Plasma gradient is excluded from product surfaces. It may be evaluated only for a future brand mark, outside this redesign.

### Type

Use Android's system Roboto through Flutter's Material type scale. Do not depend on the unlicensed Roobert reference or web font loading. Existing ad hoc Inter and Plus Jakarta Sans declarations migrate to themed Material roles:

- `headlineSmall`: primary screen title.
- `titleLarge` and `titleMedium`: record identifiers and section titles.
- `bodyLarge` and `bodyMedium`: operational content and supporting text.
- `labelLarge` and `labelMedium`: controls, chips, and compact metadata.

Text scales with Android font settings. Tight negative tracking is restricted to large headings and never applied to body text or codes.

### Shape, spacing, and elevation

- Base spacing unit: 8dp, with 4dp allowed only for internal label/icon alignment.
- Screen outer spacing: 16dp compact, 24dp expanded.
- Card radius: 20–24dp.
- Button radius: 16–20dp.
- Badge radius: 4–8dp.
- Minimum touch target: 48×48dp; minimum 8dp between independent targets.
- Cards and controls are flat. Separation comes from white-on-porcelain contrast and a Mist outline. Shadows are reserved for transient elevation such as dialogs, bottom sheets, and the floating navigation surface.

## Structure and Components

Material 3 remains authoritative for Android behavior:

- Navigation bar on compact widths; navigation rail or drawer on expanded widths.
- Top app bars provide screen context; system and predictive Back remain functional.
- Dialogs interrupt only required decisions. Bottom sheets handle contextual selection or detail. Snackbars provide transient feedback and optional recovery actions.
- Forms use themed outlined fields, readable labels, visible validation, IME insets, and actions that remain reachable above the keyboard.
- A screen or modal exposes at most one filled magenta action. Secondary actions use Ink tonal or outlined treatment; tertiary actions use text treatment.
- White record cards carry identifiers, status text, metadata, and one clear action hierarchy. Avoid nested decorative cards.
- Badges use compact inventory-label geometry and semantic color pairs. They never use the brand magenta for operational status.
- Scanner remains a dark camera surface. White framing and clear instructions lead; amber may indicate active scan mode. The rest of the app remains light.
- Existing role-specific navigation is retained: maintenance destinations for technicians, order/invoice destinations for PIC, and explicit mode switching for Admin.

## Screen Migration

The redesign covers the entire Flutter application:

1. App theme, tokens, typography, system surfaces, and shared controls.
2. Splash and login.
3. Technician and PIC/Admin home surfaces, navigation, profile, and mode switch.
4. Scanner, manual code entry, component catalog, component detail, checking, service, schedules, and history.
5. Orders, order detail and creation, component allocation, invoices, payment, PDF progress/success, and related dialogs.
6. Shared loading, empty, failure, offline/network, session-expired, destructive confirmation, and success states.

Migration is a clean cutover. Raw color, radius, font-family, and text-size declarations move to semantic theme roles or narrowly named component tokens. Do not retain a second visual system or compatibility aliases.

## Interaction and Motion

- Preserve current task order and navigation behavior.
- Use Material fade-through when content changes in place and shared-axis for hierarchical navigation where Flutter support is stable.
- Motion is short, interruptible, and limited to opacity and transform. Avoid layout animation during data entry.
- Honor Android Remove animations/reduced-motion behavior with a crossfade or immediate state change.
- Scanner lifecycle behavior remains unchanged: stop after a result, navigation away, app pause, or logout.

## State Design

- Loading preserves layout using skeletons or bounded progress indicators; it does not replace the entire screen with an unrelated composition.
- Empty states name what is absent and expose the relevant next action where the user can act.
- Network and server failures retain truthful Indonesian messages and a retry action when retry is safe.
- Validation appears beside the relevant field. Submission remains blocked until required input is valid.
- Destructive operations remain red and require confirmation when irreversible.
- Success appears only after the gateway confirms persistence. No optimistic success for writes.
- Long identifiers, names, event locations, invoice references, prices, and translated/large text must wrap, truncate deliberately, or scroll without breaking controls.

## Accessibility and Android Guarantees

- Maintain at least 4.5:1 contrast for normal text and 3:1 for large text and essential control boundaries.
- All icon-only controls keep tooltips and semantic labels.
- Focus order follows visual order. Keyboard and screen-reader users receive field errors and submission results.
- Respect status bar, navigation bar, display cutout, and IME insets.
- Verify system Back, tap targets, font scaling, and compact-width navigation behavior.
- Dark theme is not introduced in this migration. The product remains explicitly light except for the camera scanner; adding a complete dark scheme requires a separate product decision and full-state design.

## Architecture

`lib/app/app_theme.dart` owns semantic color roles, spacing, shape, type, and Material component themes. Shared widgets consume those roles. Feature screens use `Theme.of(context)`, `ColorScheme`, text themes, and narrowly scoped semantic tokens rather than repeated raw constants.

The migration may introduce focused theme extensions only where Material roles cannot express an established product semantic, such as condition or invoice-payment palettes. Extensions must name meaning, not appearance.

The CSS files do not ship or drive Flutter. `tokens.json` remains an import reference during migration and is removed or relocated once all relevant values are represented by Dart tokens and the final `DESIGN.md`.

## Verification

Behavior remains covered by the existing Flutter tests; update only tests whose observable visual or navigation contract intentionally changes. Add permanent tests only for meaningful role/state behavior, not token wiring.

Run:

- `dart format` on changed Dart files.
- `flutter analyze`.
- Targeted existing widget tests for each migrated screen family.
- The full `flutter test` suite after migration.

Perform one bounded emulator review covering:

- Login and authentication failure.
- Technician home and PIC home.
- Admin mode switching.
- Scanner and manual lookup.
- Component detail, checking, service, schedule, and history.
- Order creation/detail, allocation, invoice, and payment dialogs.
- Loading, empty, error, success, and destructive confirmation states.
- Compact Android phone viewport and font scale 1.3.

Capture emulator screenshots, fix all material findings in one batch, and confirm with at most one additional screenshot round. Physical camera and barcode verification remains a release gate and is not replaced by emulator evidence.

## Acceptance Criteria

- Every shipped screen uses the Porcelain Service Ledger system; no legacy cobalt/blue visual system remains except where blue has an explicit semantic meaning.
- The application contains no Glow, crypto, Solana, marketing hero, iPhone mockup, or web-only language.
- All current workflows, role permissions, navigation destinations, Indonesian product copy, and gateway behavior remain operational.
- Magenta is limited to brand action/selection and never communicates status.
- Touch targets, insets, system Back, text scaling, semantic labels, and error recovery meet the Android guarantees above.
- The final `DESIGN.md` describes the shipped Flutter world rather than the copied source reference.
