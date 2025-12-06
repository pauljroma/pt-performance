# DESIGN TOKENS – PT App

## Purpose

Define a consistent visual language for the PT app so:
- Patient views feel simple and supportive.
- Therapist views feel clean, clinical, and information-dense without clutter.
- Future design work and agents use consistent tokens.

---

## 1. Color Palette (Conceptual)

> Actual hex values can be chosen later and updated here; this is the structure.

### 1.1 Semantic Colors

- `color.primary` – Deep navy blue
  - Used for nav bars, primary buttons.
- `color.accent` – Teal/Green
  - Used for success, positive trends, primary highlights.
- `color.background` – Soft light gray / off-white
  - Used behind cards, lists.
- `color.surface` – White
  - Card backgrounds and panels.
- `color.error` – Red
  - Errors, high-risk flags.
- `color.warning` – Amber
  - Medium risk flags.
- `color.info` – Blue
  - Informational messages.

---

### 1.2 Status Indicators

- `status.good` – green accent
- `status.caution` – amber
- `status.bad` – red

These map to:
- pain state
- readiness score bands
- adherence levels

---

## 2. Typography

- Base font: San-serif (SF Pro on iOS).
- Scales:
  - `text.title1`: 28–32 pt (page titles)
  - `text.title2`: 22–24 pt (section titles)
  - `text.body`: 15–17 pt (primary text)
  - `text.caption`: 12–13 pt (secondary labels, metrics)

Use:
- Bold for key labels and metrics.
- Regular for explanations.
- Avoid more than 2 weights per screen.

---

## 3. Spacing & Layout

### 3.1 Spacing Tokens

- `space.xs` = 4 pt
- `space.sm` = 8 pt
- `space.md` = 16 pt
- `space.lg` = 24 pt
- `space.xl` = 32 pt

Guidelines:
- Outer padding: `space.md`–`space.lg`
- Spacing between related elements: `space.sm`
- Spacing between sections: `space.md`–`space.lg`

---

## 4. Component Styles

### 4.1 Cards

- Background: `color.surface`
- Radius: 10–16 pt
- Shadow: subtle (0–2 pt blur)
- Padding: `space.md`
- Use for:
  - Patient tiles
  - Key metrics (readiness, pain, adherence)
  - Session summary blocks

---

### 4.2 Buttons

- Primary:
  - Background: `color.primary`
  - Text: White
  - Rounded corners
- Secondary:
  - Border: `color.primary`
  - Text: `color.primary`
  - Background: transparent or surface

States:
- Disabled: reduced opacity, no strong color.

---

### 4.3 Charts

- Simple, minimal:
  - 1–2 line series max for v1.
- Colors:
  - Pain: `status.bad` (red)
  - Adherence: `status.good` (green)
  - Velocity: `color.accent` (teal)
- Axes labeled, but keep grid lines light.

---

## 5. Interaction Patterns

### 5.1 Patient

- Primary flow: Home → Today's Session → Log → Complete.
- No more than 2 nested taps to get to any primary action.
- Use bottom tabs:
  - Today
  - History

### 5.2 Therapist

- Left-rooted navigation:
  - Patients list
  - Or tabs for: Patients, Programs, Insights
- Keep heavy metrics on iPad only where possible:
  - Use navigation stacks, not modals, for main flows.

---

## 6. Definition of Done

- All SwiftUI components reference these tokens (colors/spacing/typography).
- When tokens change, UI updates consistently.
- No ad hoc colors or inconsistent font sizes for key pages.
