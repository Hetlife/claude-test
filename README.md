# Personal Expense App — Het & Sarthak

A free, private, local-first shared expense ledger for two people. No
accounts, no cloud backend, no subscriptions, no tracking. Built with
Swift, SwiftUI, SwiftData, and MultipeerConnectivity for direct
phone-to-phone sync over the local network.

## What this is

- A native iPhone app (iOS 17+) that lets either Het or Sarthak log an
  expense — who paid, how (cash or online), what category, description,
  date, optional notes.
- A 50/50 shared-expense balance: fair share = total / 2; whoever paid less
  than their fair share owes the other the difference.
- A complete local transaction history with search, filters, and date
  grouping.
- An optional budget — an amount over a date range you set — with the
  remaining balance shown right on the Home screen when the app opens.
- Direct, manual, foreground device-to-device sync over Wi-Fi using Apple's
  MultipeerConnectivity — no server, ever.
- JSON export/import as a manual backup mechanism.

Architecture and trade-offs are documented in `BUILD_PLAN.md`.

## Web version (Chrome, right now, no install)

There's also a browser-only build of the same app (`docs/index.html`) —
same design, same 50/50 balance math, same JSON export/import schema —
for using it from Chrome/Safari today while the native app isn't installed
yet. It stores data **locally in each phone's browser only** (no shared
backend), matching the native app's local-first philosophy. See
`WEB_APP.md` for what it is, its one real limitation (no live sync between
two browsers), and how to host it yourself.

## ⚠️ Important: this was built without Xcode or a Mac

This project was generated in a Linux container with **no macOS, no Xcode,
and no Swift toolchain available**. Every source file and the
`.xcodeproj` itself were hand/script-generated and have **not been
compiled or run**. Read `BUILD_PLAN.md` and `TEST_REPORT.md` for exactly
what was and wasn't verified, and what to do if Xcode reports an error the
first time you build.

**The first thing to do is open the project in Xcode and build it.** The
architecture is intentionally simple, so any compiler error should be small
and quick to fix.

## Project layout

```
ExpenseApp/
  ExpenseApp.xcodeproj/       Xcode project
  ExpenseApp/                 App target sources (see BUILD_PLAN.md for the
                               full breakdown: Models/Persistence/Services/
                               Sync/Views/Utilities)
  ExpenseAppTests/            XCTest unit tests
SampleData/
  expenses_seed.json          Optional: your real Jaipur + SCS expense data,
                               ready to import via Settings → Import
  SEED_DATA.md                What it is, and an important caveat about
                               combined vs. per-trip balances
BUILD_PLAN.md                 Architecture, milestones, environment notes
BUILD_AND_INSTALL.md          Step-by-step: build in Xcode, install on two
                               free-provisioned iPhones
SYNC_SETUP.md                 How local-network device sync works and how
                               to pair two phones
TEST_REPORT.md                What was tested, how, and what's unverified
docs/
  index.html                   Browser version of the app (self-contained,
                                localStorage-based, sample data embedded
                                inline), ready for GitHub Pages
WEB_APP.md                     What the web version is, its limitations,
                                and how to host it yourself
```

## Quick start

1. Read `BUILD_AND_INSTALL.md` and follow it on a Mac with Xcode installed.
2. Read `SYNC_SETUP.md` once both phones have the app installed.
3. Optional: import `SampleData/expenses_seed.json` to see the app with
   real data instead of starting empty (see `SampleData/SEED_DATA.md` for
   the caveats on that specific file).

## Privacy

No account creation, no analytics, no advertising, no third-party
tracking, no cloud upload, no external API. All data is stored locally on
each iPhone. The only network activity this app ever performs is direct,
local-network sync between the two phones you choose to pair, and only
while both apps are open in the foreground.
