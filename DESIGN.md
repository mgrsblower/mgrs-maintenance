# MGRS-Maintenance design contract

## 0. Reference and scope

Adapt the local MGRS operational design vocabulary from ../mgrs-release/DESIGN.md: cobalt actions, pale canvas, white bordered surfaces, compact readable mobile information. This is a functional maintenance app using the existing product identity, not a Paper screen clone. No downloaded assets, concept art or screenshots are embedded in product screens. Native Material controls retain accessible behavior.

## 1. Atmosphere

A calm field-work utility. The main action is scanning a component; the component code and last condition are prominent. No dashboard charts, invented metrics or decorative hero.

## 2. Tokens

Canvas #F4F8FC, surface #FFFFFF, primary #147CC1, text #141820, secondary #667085, border #DDE2E8, success #137333, warning #9A6700, danger #B42318. Spacing 4/8/12/16/24/32; corner radius 12; minimum control height 48; content maximum width 640. Native platform typography: title 24, section 18, body 16, label 14. Camera background dark only while scanning.

## 3. Layout

Scan / Berkala / Riwayat navigation remains visible on home tabs. Details and forms have a back button. Single scroll column, 16px outer spacing and safe-area handling. Form actions scroll above the keyboard; no fixed overlay on inputs.

## 4. Components

Material filled and outlined buttons; outlined text fields; bordered panels; text-labelled condition chips. MGRS icon uses a standard tool symbol with product text, not a copied logo. Primary action is blue; destructive errors are red. Every icon-only control has a tooltip.

## 5. States

Async content has loading, loaded, empty and failure states with retry. Form has idle, validation, saving, uncertain, conflict and success. All condition labels are textual. Error copy never exposes SQL or exception details. Loading never claims no records.

## 6. Motion and accessibility

Use native Material feedback. No continuous decorative animation. Text scaling follows the OS. Buttons at least 48 units, semantic labels, keyboard submit, scrollable forms, disabled busy state. Scanner stops on result, navigation, app pause and logout.

## 7. Verification and debt

Verify native screens and interaction states on Android emulator; actual physical barcode/camera testing remains a release requirement. Desktop/web are not distribution targets. The schema is not deployed by UI verification. Production labels never present fixture data as real data.
