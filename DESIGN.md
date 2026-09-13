# MGRS design contract

## 0. Reference and scope

Use `C:\Users\ogi\Downloads\DESIGN-apple.md` as the visual north star, adapted for a functional Flutter Android application. This is a complete visual-world replacement, not a color refresh. The Apple reference contributes restraint, typography, surface rhythm, hierarchy, and product focus. Android Material 3 remains the platform behavior baseline.

The product has two workspaces:

- **PIC MGRS:** orderan and invoice.
- **Tim Lapangan:** maintenance, field order context, and installation confirmation.

Admin can access both workspaces. PIC MGRS and Tim Lapangan have separate shells and navigation.

## 1. Design read

A precise field-operations instrument for people working with real equipment, orders, and maintenance records. The interface should feel curated like an Apple product surface, but behave like a dependable Android work tool. The product's character comes from exact hierarchy, quiet surfaces, clear state, and one decisive action, not decorative effects.

Dials:

- ENERGY: 4
- RHYTHM: 6
- MOTION: 3
- VISUAL DENSITY: 5

## 2. Visual principles

- UI chrome recedes so the current task leads.
- Use a cool monochrome base with white, pearl, charcoal, and one Action Blue.
- Use whitespace and typography to separate concepts before adding containers.
- A surface is only elevated when elevation communicates a real interaction or hierarchy.
- No decorative gradients, glow, grain, glass, colored stripes, or floating effects without a written product purpose.
- No marketing hero, fake product gallery, invented statistics, fake avatars, or decorative dashboard sections.
- Do not preserve the current liquid-glass dock, bento dashboard treatment, or mixed invoice/maintenance shell.

## 3. Palette

Semantic roles:

- `canvas`: `#FFFFFF`
- `canvasSubtle`: `#F5F5F7`
- `surface`: `#FAFAFC`
- `surfaceStrong`: `#FFFFFF`
- `surfaceDark`: `#272729`
- `surfaceBlack`: `#1D1D1F`
- `ink`: `#1D1D1F`
- `inkOnDark`: `#FFFFFF`
- `inkMuted`: `#6E6E73`
- `divider`: `#E0E0E0`
- `actionBlue`: `#0066CC`
- `actionBlueFocus`: `#0071E3`
- `success`: `#2E7D32`
- `warning`: `#956400`
- `danger`: `#B42318`

Action Blue is reserved for primary actions, links, focus, and selected controls. Status colors are semantic and always paired with text.

## 4. Typography

Use a native/system sans family suitable for Android. If a licensed SF Pro asset is not explicitly provided, do not fake SF Pro; use the platform sans stack and preserve the Apple reference's proportion, weight, and spacing character.

Material text roles map to this scale:

- Display: 34–40, weight 600, tight tracking
- Headline: 28–32, weight 600
- Title: 20–24, weight 600
- Body: 16–17, weight 400
- Body strong: 16–17, weight 600
- Caption: 13–14, weight 400
- Label: 12–14, weight 600

Typography must come from `ThemeData.textTheme`; do not set arbitrary font sizes per screen. Body text must remain readable at enlarged system font scale.

## 5. Workspace composition

### PIC MGRS

Landing composition:

1. Workspace identity and current context.
2. Orderan requiring attention.
3. Order/pasangan status and allocation actions.
4. Invoice actions and payment status.

Navigation: Beranda, Orderan, Invoice, Profil.

### Tim Lapangan

Landing composition:

1. Workspace identity.
2. Scan component as the primary action.
3. Open field tasks and periodic work.
4. Relevant order/pasangan context.
5. Recent maintenance history.

Navigation: Scan, Berkala, Komponen, Riwayat. Servis and pemeriksaan are contextual actions from component/task detail.

### Admin

Admin has a visible switcher with exactly two choices: PIC MGRS and Tim Lapangan. Switching workspace resets to that workspace landing screen and does not change authorization.

## 6. Component language

Prefer native Material 3 controls and flat grouping:

- `NavigationBar`, `NavigationRail`, or drawer based on available width.
- Material buttons with clear hierarchy.
- Outlined or filled fields with labels above input content.
- `ListTile`, dividers, and whitespace for repeated records.
- Cards only when a record or action genuinely needs a boundary.
- Status badges only for real status values.
- Bottom sheets and dialogs only for focused decisions.
- Every icon-only control has a semantic label and tooltip.
- Every interactive target is at least 48dp with visible focus.

Shared components must own spacing, semantics, state, and interaction. Workspace components own domain content and vocabulary.

## 7. State and motion

Every data view has explicit loading, empty, error, retry, and permission states. Forms have idle, validation, saving, uncertain, conflict, success, and discard states. Loading never implies empty data.

Motion is quiet and purposeful:

- Use Material transitions for navigation and sheets.
- Use short transform/opacity feedback for press and selection.
- No perpetual decorative loops.
- Scanner animation runs only while scanning.
- Respect reduced-motion settings with crossfade or immediate state changes.
- Never animate layout properties for decoration.

## 8. Content integrity

- No invented numbers, customer names, avatars, testimonials, or operational claims.
- Empty values stay empty or use explicit contextual placeholders.
- Service examples belong in hint text, never initial field values.
- Checking forms never default to a successful condition.
- Status text is Indonesian, specific, and action-oriented.

## 9. Responsive and Android rules

- Compact width uses Material NavigationBar.
- Expanded width uses NavigationRail or drawer and a wider content composition.
- Define compact, medium, and expanded layout states based on content breakage, not device names.
- No horizontal overflow or clipped text.
- Forms reserve IME space and keep the focused field visible.
- System Back and predictive Back remain functional.
- Verify light/dark appearance, 1.3 font scale, portrait, landscape, and expanded width.

## 10. Anti-slop delivery gate

Apply the global `antislop`, `antislop-ui`, `antislop-human`, and `antislop-layoutmobile` skills **during** planning and implementation.

Before shipping, verify:

- Every visual technique has a product purpose.
- Every interactive control works or is removed.
- Navigation points to real destinations.
- Real data is used; no fabricated metrics or content.
- Contrast and non-text boundaries meet WCAG AA expectations.
- Focus, semantics, empty/loading/error, conflict, and retry states are perceivable.
- Mobile, medium, and expanded layouts are intentionally designed.
- The result remains recognizably MGRS even without the logo or product name.

## 11. Verification debt
 
Verify the native app on Android emulator and, before release, physical hardware for camera, barcode, gestures, keyboard, and network conditions. UI verification does not prove database deployment or live policy compatibility.

## 12. Shipped implementation boundaries

- **Installation confirmation**: Exposes read-only order identity and pasangan context with an explicit status indicator (`Konfirmasi pemasangan belum tersedia`) pending backend RPC availability. No unverified write endpoints or fake save buttons are implemented.
- **Surface separation**: Invoice features in order detail views are strictly restricted to users with `canManageOrders` (PIC MGRS and Admin), maintaining complete workspace isolation for Tim Lapangan.
- **Platform packaging**: Android v2 embedding is enforced in `AndroidManifest.xml` alongside native `FileProvider` PDF support, ensuring reproducible and clean APK builds.

