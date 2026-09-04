# Hissa — حصة

**Own your share.** A Flutter **pitch demo** for a fractional US-stock investing app
built for the Egyptian market.

The demo opens in **English, dark theme, as Nour**. Arabic + RTL is fully
supported and one tap away in Settings — every screen is laid out RTL-first.

> This is a demo build for a fintech competition. There is **no backend, no API and
> no real authentication**. Every number comes from a static local snapshot, and the
> app makes **zero network calls** at runtime.

---

## Run it

```bash
flutter pub get
flutter run                 # Android / any attached device
flutter run -d chrome       # web
flutter build web --release # deployable web build in build/web
```

Tests:

```bash
flutter test
```

---

## The demo path

The pitch runs end to end without a stumble:

**onboarding → OTP → ID scan → risk profile → home → invest → stock detail →
buy a fraction → success → plans → demo trial → AI chat**

- **OTP accepts any 6 digits.** A mock notification banner slides in ~1.5s after
  the screen appears, carrying the code; tapping it autofills the boxes. It is a
  widget in our own tree, not a real platform notification. **Resend** issues a
  new code and a fresh banner.
- Every KYC field validates as valid; nothing can fail.
- **Deposit** adds EGP 1,000 to the demo balance, so you can always keep buying.
- **Start demo trial** on the Plans page unlocks the AI advisor instantly (in-memory
  flag, no payment flow).
- **Settings → Reset demo** restores the portfolio, balances and chat to their
  opening state. Language and theme are left alone — those are the presenter's
  stage settings, not demo data.

Skipping ahead: the splash screen has a **Skip** link straight to Home, and every
tab is reachable from the bottom bar.

---

## The screen that matters

`lib/screens/buy/trade_screen.dart` is the hero. Before the user confirms, it shows
simultaneously — and updates on every keystroke:

- the live share price
- the FX rate applied, with a `locked · 0:58` countdown
- the amount in USD
- **the fraction of a share being bought**, rendered as the largest thing on screen
- the trade commission (0.1%), the flat fee, and the total

The sell variant is the same screen with `isBuy: false`, plus a **Sell all** chip.

---

## Tuning it

Everything tunable lives in **`lib/app/constants.dart`**: brand colours, the
EGP/USD rate, commission rate and flat fee, minimum order, quick-select amounts,
tier prices, the rate-lock duration, and the simulated tick.

Tier pricing is read from there via `lib/models/plan.dart`, so changing
`K.tier2Egp` / `K.tier3Egp` updates the comparison table and the CTAs together.

---

## Data

`assets/data/` holds three static JSON files — 20 real companies and ETFs with
realistic prices, plus a pre-populated portfolio and transaction history. They carry
an `as_of` date, surfaced unobtrusively in the app as
*"Prices as of 2026-08-28 · illustrative demo data"*.

They are **generated**, so the snapshot is reproducible:

```bash
dart run tool/gen_data.dart
```

Edit the seed table in `tool/gen_data.dart` (prices, day changes, market caps,
Arabic descriptions, per-ticker drift and volatility) and re-run.

A **gentle simulated tick** nudges displayed prices every 5 seconds by up to ±0.3%,
tethered to within ±2% of the snapshot close so a stock quoted as up never charts as
down. It is presentation only — it never touches the stored data.

---

## Company logos

`lib/app/brands.dart` maps every ticker to its real brand colour and, where one
is bundled in `assets/logos/`, a real brand mark drawn in white on that colour.
Twelve companies have marks; Microsoft, Amazon, Disney and JPMorgan are not in
the bundled icon set and the four ETFs have no logotype, so those tiles show the
ticker on the same authentic brand colour — the set still reads as one system.
The marks are trademarks of their respective owners, used only to identify the
security being quoted.

## Brand

Everything brand-related is derived from **one image**, `tool/logo.png` — the
Hissa wordmark, white on navy. Replace that file and re-run:

```bash
python tool/gen_brand.py
```

It lifts the artwork off its navy ground into white-on-transparent PNGs (so the
mark sits on any background and can be tinted), splits the `H` glyph from the
lockup at the gap it finds in the source, and writes:

| Output | Used by |
|---|---|
| `assets/brand/hissa_wordmark.png` | the web loading screen, the in-app splash |
| `assets/brand/hissa_mark.png` | `HissaMark` — notification, Settings, processing |
| `web/icons/*`, `web/favicon.png` | PWA + browser tab |
| `android/.../mipmap-*/ic_launcher.png` | legacy launcher icon (below API 26) |
| `android/.../mipmap-*/ic_launcher_foreground.png` | adaptive icon + API 31+ splash |
| `android/.../drawable/hissa_launch.png` | launch screen below API 31 |

The **loading screen** is painted twice over, identically, so the handover is
invisible: `web/index.html` draws the wordmark in plain HTML/CSS before the
Flutter engine boots (the default is a blank page — a bad first second in front
of judges), and the in-app splash draws the same PNG a moment later. Android
gets the mark as its native launch drawable, on the same navy sampled from the
source (`#142D70`).

Android needs two extra pieces, both of which supply **our** navy so the system
never puts a white plate behind the mark:

- `mipmap-anydpi-v26/ic_launcher.xml` — an adaptive icon whose background layer
  is `@color/hissa_navy`. Without it, launchers treat the square icon as a
  foreground and drop it on a default white background.
- `values-v31/styles.xml` — API 31+ ignores the custom launch drawable and
  builds its own splash from the app icon. This points it at our navy and our
  mark, and deliberately leaves `windowSplashScreenIconBackgroundColor` unset so
  the mark sits straight on the navy rather than inside a white circle.

## Layout

```
lib/
  app/         constants, theme, router, localisation, formatters
  models/      Stock, Holding, Txn, Plan, DemoUser, ChatMessage
  services/    MockDataService, PriceTickService, ChatService
  providers/   App, Market, Portfolio, Subscription, Chat  (provider)
  screens/     onboarding/ home/ wallet/ invest/ buy/ plans/ chat/ settings/
  widgets/     shared components
assets/
  data/        the static snapshot
  brand/       Hissa wordmark + mark (generated)
  fonts/       Cairo (bundled, see below)
  logos/       company brand marks
tool/          gen_data.dart, gen_brand.py, logo.png
```

State is `provider`; routing is `go_router` with a five-tab
`StatefulShellRoute`. Nothing is persisted — a restart is a clean demo.

## Fonts

Cairo is **bundled** in `assets/fonts/` and `GoogleFonts.config.allowRuntimeFetching`
is set to `false` in `main.dart`. `google_fonts` would otherwise fetch the font from
Google's CDN on first paint — a network dependency, and one bad conference Wi-Fi
away from an unstyled first slide. Cairo is licensed under the SIL Open Font License
(`assets/fonts/OFL.txt`).

## Localisation

The demo opens in English; the Settings toggle flips the whole tree to Arabic and
RTL (change the defaults in `lib/providers/app_provider.dart`). Strings live in a single table in
`lib/app/strings.dart` behind a real `LocalizationsDelegate`, so `Directionality`,
Material widgets and `intl` all resolve from one locale.

Numerals are Western in both languages — deliberately consistent, and what Egyptian
banking apps generally show. The labels localise; the digits do not.
