# Build & Install — Personal Expense App

This gets the app onto both of your iPhones for free, using a personal
Apple ID (no paid Apple Developer Program membership required).

## Requirements

- A Mac running a recent macOS with **Xcode 15 or newer** installed
  (Xcode 16 also works — the project targets iOS 17.0, which both support).
- A free Apple ID (just a regular iCloud account — no paid enrollment).
- Two iPhones (Het's and Sarthak's), each running iOS 17 or later.
- A USB or USB‑C cable to connect each iPhone to the Mac (or Wi‑Fi
  debugging enabled in Xcode, if you prefer).

## 1. Open the project

1. Copy/unzip the `ExpenseApp` folder onto the Mac.
2. Double-click `ExpenseApp/ExpenseApp.xcodeproj` to open it in Xcode.
3. Let Xcode finish indexing.

## 2. First build — do this before anything else

Since this project was generated without access to Xcode, **build it once
before touching signing settings**, so any compiler error surfaces early:

1. Select the **ExpenseApp** scheme (top toolbar) and any iPhone simulator
   as the run destination (e.g. "iPhone 16").
2. `Product → Build` (⌘B).
3. If it fails: the codebase is small and each file is short — the error
   message will point at the exact file/line. Fix and rebuild. Also run
   `Product → Test` (⌘U) once the build succeeds, to run the XCTest suite.

## 3. Set a unique Bundle Identifier

1. Select the **ExpenseApp** project in the navigator → select the
   **ExpenseApp** target → **Signing & Capabilities** tab.
2. Change **Bundle Identifier** from `com.hetsarthak.expenseapp` to
   something unique to you, e.g. `com.<yourname>.expenseapp`. Apple
   requires bundle IDs to be globally unique per Apple ID.
3. Repeat for the **ExpenseAppTests** target if you plan to run tests on
   a device (its ID is `com.hetsarthak.expenseapp.ExpenseAppTests` —
   change the prefix to match).

## 4. Set your Signing Team

1. Still in **Signing & Capabilities**, under **Signing**, check
   **Automatically manage signing**.
2. Under **Team**, choose your Apple ID. If it's not listed:
   **Xcode → Settings → Accounts → +** → sign in with the Apple ID you
   want to use for development.

## 5. Install on Het's iPhone

1. Connect Het's iPhone via cable.
2. If prompted on the phone, **Trust This Computer**.
3. In Xcode's run-destination picker (top toolbar), select Het's iPhone.
4. `Product → Run` (⌘R).
5. **First launch on the phone will be blocked** by iOS with an
   "Untrusted Developer" message. On the iPhone: **Settings → General →
   VPN & Device Management** → tap your Apple ID under "Developer App" →
   **Trust**.
6. Re-launch the app from the Home Screen.

## 6. Install on Sarthak's iPhone

Repeat step 5 with Sarthak's iPhone connected instead. You do **not** need
to change the Bundle Identifier again — both phones run the *same* app
build; they're just two independent installs of it.

## 7. First launch on each phone

1. The app shows a one-time screen asking **"Who is using this iPhone?"**
   — pick Het on Het's phone, Sarthak on Sarthak's. This only sets
   defaults; either phone can still log an expense for the other person
   at any time.
2. You're in. Tap **+** to add your first expense.

## 8. Set up sync between the two phones

See `SYNC_SETUP.md` for the full walkthrough (Local Network permission,
finding the other device, pairing, and syncing).

## Important limitation: free-provisioning expiry

Apps installed this way (a free Apple ID, no paid Apple Developer Program)
are signed with a certificate that **expires after about 7 days**. After
that, the app icon will show "Untrusted App" / it won't open until you
rebuild and reinstall from Xcode — same steps as above (reconnect the
phone, `Product → Run`). Your expense data is untouched by this — it's
stored locally on the phone and survives reinstalls **as long as you don't
delete the app** in between. If you do delete it, your data is gone unless
you'd exported a backup first (**Settings → Export Expenses**) — do this
regularly.

If you'd rather not reinstall every week, a paid Apple Developer Program
membership ($99/year) gives certificates valid for a full year and access
to TestFlight for easier reinstalls — but that's a paid option the product
spec explicitly avoids requiring. This document does not tell you the app
can be permanently installed for free: it cannot, without periodic
rebuilds.

## Troubleshooting

- **"Failed to register bundle identifier"** — your chosen Bundle
  Identifier is already taken by someone else's app. Change it to
  something more unique (e.g. add your surname or a random suffix).
- **"No account for team"** — sign into your Apple ID under Xcode →
  Settings → Accounts first.
- **App won't launch, no error shown** — check
  Settings → General → VPN & Device Management on the phone and make sure
  your developer certificate is trusted (step 5.5 above).
- **Build succeeds but a specific screen misbehaves** — please report the
  exact error/behavior; the code was written carefully but was never
  compiled in this environment, so a first-build issue is plausible and
  should be easy to pinpoint from the error location.
