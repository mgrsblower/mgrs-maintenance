# Porcelain Service Ledger

## Purpose and scope

Porcelain Service Ledger is the shipped visual system for the **MGRS-Maintenance Android app**. It is an Android-native Flutter/Material 3 system for workshop, warehouse, and customer-site work—not a marketing site.

The interface stays in Indonesian and preserves the product workflow:

- **Tim Service** and **Tim Pemasangan** identify Kepala, Batang, or Tabung by QR/barcode or unique code, inspect condition, record routine checks or service, and review history.
- **PIC Pemasangan** manages orderan, component allocation, invoice, payment status, and PDF sharing/export.
- **Admin** switches explicitly between Mode Servis and Mode PIC; the two workspaces retain their separate destinations and permissions.

The visual source of truth is the shipped Dart implementation, especially [`lib/app/app_theme.dart`](lib/app/app_theme.dart). The copied web reference is not a runtime contract.

## Visual foundation

The app is light and flat by default. Porcelain is the canvas, white is the work surface, and Ink supplies structure. Cards are separated by surface contrast and Mist outlines rather than decorative shadows.

### Color tokens

| Token | Value | Role and restrictions |
| --- | --- | --- |
| `porcelain` | `#F4F5F6` | Screen canvas and light app-bar background. |
| `white` | `#FFFFFF` | Cards, form surfaces, dialogs, sheets, navigation surface, and primary-on-color text. |
| `ink` | `#131517` | Primary text, structural controls, selected navigation, icons, and neutral emphasis. |
| `graphite` | `#333537` | Tertiary text and neutral high-contrast details. |
| `stone` | `#737577` | Supporting text, hints, inactive icons, and metadata. |
| `mist` | `#B3B5B7` | Borders, outlines, disabled dividers, and control boundaries. |
| `mistLight` | `#E3E4E6` | Tonal containers, navigation indicators, tracks, and quiet separators. |
| `magenta` | `#CC62D5` | Brand action, focused field outline, progress indicator, and selection only when no competing primary action is visible. |
| `success` / `successSurface` | `#23663A` / `#E9F6EE` | Confirmed, healthy, complete, or paid state. |
| `warning` / `warningSurface` | `#8A5A00` / `#FFF3D6` | Attention, partial, pending, or degraded state. |
| `danger` / `dangerSurface` | `#B42318` / `#FDEBEC` | Error, invalid, destructive, cancelled, or unsafe state. |

`ColorScheme` owns general Material roles. `OperationalColors` is the semantic `ThemeExtension` for success, warning, and danger surface/foreground pairs.

A screen or modal has at most one filled magenta action. When that action is visible, navigation and selection use Ink or Ink-tonal treatment. Magenta **never** means success, warning, danger, payment, component condition, connectivity, or completion. Every operational state also has text and/or an icon; color is never the only signal.

There is no dark theme. The scanner is the sole permanently dark surface (see [Scanner exception](#scanner-exception)).

## Typography

`maintenanceTheme()` uses Android Material 2021 typography (`Typography.material2021(platform: TargetPlatform.android)`), which resolves to the Android system Roboto family. Do not add remote or web fonts.

| Material role | Shipped use |
| --- | --- |
| `headlineSmall` | Screen titles and primary section headings. |
| `titleLarge`, `titleMedium` | Record identifiers, card headings, and section titles. |
| `bodyLarge`, `bodyMedium` | Operational content, instructions, form copy, and supporting text. |
| `bodySmall` | Secondary explanations and compact detail. |
| `labelLarge`, `labelMedium`, `labelSmall` | Buttons, chips, badges, filters, navigation labels, and compact metadata. |

Text must remain readable at Android font scales. Tight tracking is limited to large headings where already defined by the theme; body text, codes, names, and identifiers do not use decorative tracking. New screens consume `Theme.of(context).textTheme` instead of declaring a font family, arbitrary type scale, or per-screen typographic system.

## Spacing, shapes, and elevation

- Base rhythm: **8dp**. `4dp` is reserved for compact icon/label alignment.
- Shared spacing tokens: `4`, `8`, `12`, `16`, `24`, and `32dp`.
- Screen content: normally `16dp` outer padding, expanding to `24dp` for focused forms and dialogs.
- Shared content width: `640dp` maximum on wider Android windows; content remains a single readable column.
- Card radius: **22dp** (`20–24dp` family).
- Control/button radius: **18dp** (`16–20dp` family).
- Badge/chip radius: **6dp** (`4–8dp` family).
- Independent targets are at least **48×48dp**, with at least **8dp** separation.
- Cards and controls are elevation 0 with a Mist border. Transient Material surfaces may elevate: navigation surface around 3, dialogs/sheets around 6, and floating snackbars around 6.

Avoid nested decorative cards. A white record card should carry the identifier, status, metadata, and one clear action hierarchy.

## Components and screen patterns

### App shell and navigation

`lib/app/app.dart` keeps authentication, role routing, mode switching, and destinations intact. The compact Android shell uses a Material `NavigationBar` with a white surface, 72dp height, MistLight selected indicator, and Ink selected icon/label. Technician destinations are **Beranda**, **Aset**, and **Servis**; PIC destinations are **Beranda**, **Orderan**, and **Invoice**. The scanner is a separate 56dp floating action with the only magenta scanner entry action.

The shell uses `SafeArea`, preserves system/predictive Back, and leaves space for the navigation surface. Page content is scrollable and bounded rather than arranged as a web marketing grid. Forms and dialogs use `LayoutBuilder` to stack fields when a phone width is constrained.

### Cards, lists, and status badges

Cards use the themed white surface, 22dp radius, Mist outline, and 16dp internal padding as the common starting point. Lists and record details keep long codes, customer names, invoice references, and locations wrapped or deliberately scrollable without pushing actions out of reach.

`ConditionBadge` and feature status treatments use semantic pairs:

- `OK`, healthy, complete, or paid → success green on success surface.
- `Rusak Ringan`, partial, pending, or attention → warning amber on warning surface.
- `Rusak Berat`, `Perlu Servis`, cancelled, invalid, or unsafe → danger red on danger surface.
- Unpaid, neutral history, and unselected data use Ink/Stone/MistLight neutrals rather than pretending to be successful.

Invoice payment mapping is explicit: **Lunas** is success, **Sebagian** is warning, **Dibatalkan** is danger, and **Belum Bayar** is neutral. Labels and icons accompany each color treatment.

### Buttons and controls

The Material themes in `app_theme.dart` are authoritative:

- Filled buttons are the single filled magenta action when a primary action exists; they are at least 48dp high, use white text, 18dp radius, and no decorative elevation.
- Outlined buttons use Ink text and a Mist outline for secondary/recovery actions.
- Text buttons are tertiary actions.
- Icon buttons are at least 48dp with Ink foreground and a tooltip/semantic label when icon-only.
- Checkboxes, radios, switches, segmented controls, chips, and progress indicators use Material roles and the semantic palette; they do not introduce another visual language.

### Forms and feedback

Inputs are white, themed outlined fields with 18dp radius, 16dp horizontal/vertical content padding, Stone hints, a 2dp magenta focus outline, and danger error borders/text. Forms remain scrollable above the IME (`resizeToAvoidBottomInset`, insets, and keyboard dismissal are preserved). Validation appears beside the relevant field and submission is blocked until required input is valid.

Loading preserves the surrounding task with a bounded progress indicator or skeleton. `AsyncStateView` maps progress to the primary theme role and failure to danger, announces failures as a live region, preserves truthful Indonesian error text, and offers **Coba lagi** when retry is safe. Empty states explain what is absent and expose the next relevant action.

Dialogs are white Material surfaces with 16–24dp insets, 24dp content padding, a Mist outline/22dp card shape, and elevation reserved for interruption. Destructive confirmation remains red and requires confirmation. Bottom sheets are white, modal, SafeArea-aware, show a drag handle, and use the 22dp top radius for contextual selection or detail. Snackbars are floating Ink surfaces with readable white content and recovery actions.

### Motion and press feedback

Motion is short, interruptible, and limited to opacity or small transforms:

- role/page changes use a brief fade with up to 4dp vertical travel;
- navigation transitions use a short Material fade;
- `PressableScale` provides visible pressed feedback (subtle scale toward `0.975`) and light haptic feedback;
- reduced-motion settings are read through `MediaQuery.disableAnimationsOf(context)` and switch transitions to an immediate state or zero duration.

No layout animation should interfere with data entry. Scanner lifecycle behavior is unchanged: the camera stops after a result, when the scanner is left, when the app pauses, and on logout.

## Scanner exception

`ScanScreen` is intentionally different because it is a camera tool rather than a record surface. It is the only permanently dark screen: a black edge-to-edge camera preview, white viewfinder corners/laser, translucent black top controls, and a docked result sheet. Touch-to-focus and torch feedback may use bounded amber accents. Close, torch, and lens controls retain 48dp targets, Indonesian tooltips, and semantic labels; SafeArea protects the top controls and bottom inset.

The scanner's translucent camera vignette is an exception to the otherwise flat, no-gradient product surfaces. Do not reuse its dark overlays, camera gradient, laser, or amber focus treatment in home, forms, cards, invoices, or navigation.

## Accessibility and Android guarantees

- Use Material semantics and visual focus order. Icon-only actions keep a `Tooltip` and a spoken label.
- Keep minimum 48×48dp targets and 8dp separation, including scanner controls and navigation destinations.
- Respect status/navigation bars, display cutouts, SafeArea, predictive/system Back, and IME insets.
- Keep normal text contrast at least 4.5:1 and large text/essential boundaries at least 3:1.
- Never communicate a state by color alone; pair semantic color with a label, icon, or supporting text.
- Honor Android font scaling, including the 1.3 review target, without clipping or overlap.
- Announce asynchronous failures and submission results; keep focus and error copy associated with the relevant field.

## Implementation map and explicit bans

- Theme and tokens: [`lib/app/app_theme.dart`](lib/app/app_theme.dart)
- Role shell and transitions: [`lib/app/app.dart`](lib/app/app.dart)
- Shared navigation, async feedback, press feedback, and condition semantics: [`lib/shared/`](lib/shared/)
- Representative shipped surfaces: `lib/features/auth/`, `home/`, `maintenance/`, `components/`, `scan/`, `schedule/`, `history/`, and `invoices/`.

Do not reintroduce:

- copied web CSS, web font loading, responsive marketing/landing-page language, or a second token system;
- crypto, Solana, wallet, iPhone mockup, product-hero, conversion, or other unrelated reference language;
- gradients or dark surfaces outside the scanner exception;
- magenta as a status, payment, connectivity, condition, success, warning, or danger signal;
- raw per-screen font families, arbitrary typography scales, or duplicated visual constants when a Material role/token exists;
- unverified production, deployment, benchmark, testimonial, or device-coverage claims.

Indonesian product copy, gateway calls, data behavior, role permissions, and navigation destinations remain product truth and must not be changed to satisfy visual styling.

## Verification and known visual limitation

This document records the shipped Flutter code, not an unverified design intention. Code-level review covered the theme contract, shared components, role shell, feature screen families, status mappings, scanner lifecycle, Indonesian workflows, and accessibility hooks.

The bounded Android visual review could not be completed: launching the Flutter app on Windows failed in the PTY with **error 193**. Consequently, no Android emulator screenshots were captured, no claim is made about device pixels or physical camera/barcode behavior, and the expected `.impeccable/review/android-phone*.png` evidence is absent. Emulator launch, normal/font-scale review, physical camera/barcode testing, production deployment/signing, real QA accounts, and cross-application interoperability remain release gates.
