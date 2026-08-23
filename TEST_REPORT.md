# Test Report — Personal Expense App

## Environment used for this build

This project was built in a **Linux container with no macOS, no Xcode, and
no Swift toolchain** (`swift`, `xcodebuild` are not installed; no
simulator, no physical iPhone attached). This is stated up front in
`BUILD_PLAN.md` and repeated here because it directly determines what
"tested" can honestly mean below.

**Nothing in this project has been compiled or executed by a Swift/Xcode
toolchain.** No `xcodebuild build`, no `swift test`, no simulator run, no
on-device run were performed or could be performed here. Any claim below
of a test "passing" means: **the test was written, and its logic was
independently verified by careful manual tracing / a separate Python
re-implementation of the same arithmetic — not by running XCTest.**

**The very first thing to do with this project is open it in Xcode and
build it (`BUILD_AND_INSTALL.md`, step 2).** A static-review pass (below)
already caught and fixed several real compile errors that only a type
system would normally catch (see "Bugs found and fixed" below) — there may
be more that only Xcode's actual compiler will surface. The architecture
is intentionally small and modular, so a first-build fix should be
localized to one file.

## What "static validation" means here, concretely

In place of a compiler, the following was done for every one of the 39
Swift source/test files:

1. **Structural balance check** — a script verified every file has
   balanced `{}`, `()`, `[]`, correctly skipping string/character literals
   and comments. All 39 files passed.
2. **Manual protocol-conformance audit** — every `enum`/`struct`
   declaration was checked against every place it's compared with `==`,
   used as a `Picker`/`ForEach` selection, or passed to `XCTAssertEqual`,
   since Swift does **not** auto-derive `Equatable`/`Hashable` unless the
   conformance is explicitly declared, even for simple enums.
3. **Manual API-signature audit** — every SwiftUI/SwiftData/
   MultipeerConnectivity/Foundation API call was checked against its real
   signature from memory (init parameter labels, property wrapper usage,
   `@MainActor`/`nonisolated` correctness for the `MCSessionDelegate`
   conformance, etc.).
4. **`project.pbxproj` internal consistency** — generated via a Python
   script (not hand-typed) specifically to avoid transcription errors; a
   second script independently verified every UUID referenced anywhere in
   the object graph resolves to a real object, and vice versa (0 dangling
   references, 0 unreferenced objects, across 114 objects).

## Bugs found and fixed during static review

Real, would-not-have-compiled bugs, caught before ever reaching Xcode:

- `Payer`, `PaymentMethod`, `ExpenseCategory`, `HomePeriod`, and
  `SyncMessage.Kind` were originally declared without `Hashable`/
  `Equatable` conformance, despite being used with `==`, as `Picker`
  selections, and in `XCTAssertEqual`. Swift does not synthesize these
  automatically without an explicit declaration. Fixed by adding
  `Hashable`/`Equatable` to each. This would have broken the build in
  `BalanceCalculator.swift`, every filter in `TransactionsView.swift`, the
  `Picker`s in `AddExpenseView.swift`/`HomeView.swift`, and several test
  files — i.e., most of the app.

No other issues were found in the review pass, but again: **this is not a
substitute for an actual build.**

## Unit test coverage (written, logic-verified, not yet run by XCTest)

`ExpenseAppTests/` — 9 files, ~60 test methods:

- **`BudgetCalculatorTests.swift`** — spend inside/outside a budget's date
  range, inclusive start/end boundaries, over-budget flagging, deleted
  expenses excluded, empty ledger, and a single-day budget window.
- **`BudgetTests.swift`** — validation: zero amount rejected, end date
  before start date rejected, same-day start/end accepted.

- **`BalanceCalculatorTests.swift`** — every scenario from the product
  spec: Het pays ₹1,000 → Sarthak owes ₹500; Sarthak pays ₹1,000 → Het
  owes ₹500; equal payments → settled; mixed transactions; odd totals down
  to single-paise precision; deleted expenses excluded; empty ledger;
  large amounts (no overflow at ₹10 lakh+ scale).
- **`SyncEngineTests.swift`** — the pure merge algorithm covering the
  spec's full sync test matrix that doesn't require physical hardware: new
  remote record added, union of independent offline edits, same-UUID
  conflict resolved by latest `updatedAt`, stale update ignored, tie
  resolved deterministically, tombstone propagation, tombstone doesn't
  resurrect from a stale un-deleted copy, repeated sync is a no-op
  (idempotent, no duplicates), invalid records rejected not merged, empty
  batch handled.
- **`SyncMessageCodecTests.swift`** — wire protocol round-trips
  (hello/expenseBatch), malformed data rejected without crashing,
  unsupported protocol version rejected, batching splits large sets
  correctly (450 records → 3 batches of ≤200), empty-set batching.
- **`ExportImportServiceTests.swift`** — export/parse round-trip, exact
  filename format, malformed JSON rejected, wrong schema version rejected,
  duplicate-UUID import updates instead of duplicating, import never
  overwrites a newer local edit, invalid records in an import are rejected
  without corrupting existing data.
- **`ExpenseRepositoryTests.swift`** — insert → fetch, update bumps
  `updatedAt`, soft-delete hides from active list but keeps the tombstone,
  deleting a nonexistent record throws, data persists across repository
  instances sharing a container (simulates app relaunch), batch upsert,
  newest-first sort ordering.
- **`ExpenseRecordTests.swift`** — validation rules: zero/negative/
  oversized amounts rejected, boundary amount accepted, empty description
  rejected, non-INR currency rejected, non-finite date rejected.
- **`CurrencyFormatterTests.swift`** — whole-rupee amounts show no
  decimals, fractional amounts show exactly two, zero handled, VoiceOver
  string always shows two decimals.

## Independently verified: real seed data

`SampleData/expenses_seed.json` (70 real transactions from the user's own
Jaipur trip + SCS accounting) was generated by a Python script that
**asserts** its own output sums to the exact same totals as the source
accounting document before writing the file — this ran successfully:

```
Jaipur: 57 txns, total ₹81460 (expected 57, ₹81,460)
  Het ₹35339 (expected ₹35,339)  Sarthak(incl. unnamed) ₹46121 (expected ₹46,121)
SCS: 13 txns, total ₹16570 (expected 13, ₹16,570)
  Het ₹4600 (expected ₹4,600)  Sarthak(incl. unnamed) ₹11970 (expected ₹11,970)
All totals match the source accounting document.
Combined: total ₹98030, Het paid ₹39939, Sarthak paid ₹58091, fair share ₹49015
  -> Het owes Sarthak ₹9076
```

This combined result (₹9,076) matches the source document's own "COMBINED
POSITION" section exactly, which is independent evidence that
`BalanceCalculator`'s arithmetic (implemented identically in Swift and
re-derived in Python for this check) is correct. See
`SampleData/SEED_DATA.md` for the important caveat that the app's v1 flat
ledger shows this combined number, not the two separate trip settlements
the source document also computes.

## Explicitly NOT tested (no hardware/toolchain available)

- **Phase 10's full two-phone test matrix (A–J)** requires two physical
  iPhones and was not run: real MultipeerConnectivity discovery/pairing
  over real Wi-Fi, backgrounding/foregrounding behavior, actual Local
  Network permission prompts, real disconnect/reconnect handling. The
  underlying merge logic those tests would exercise **is** covered by
  `SyncEngineTests.swift`, which is the part most likely to have a real
  bug; the MultipeerConnectivity transport code
  (`PeerSyncManager.swift`) is the part that could still contain a
  runtime-only issue (e.g. a delegate callback timing edge case) that no
  static review can catch.
- **UI/visual QA** (Phase 9's "inspect every screen at small/large iPhone,
  light/dark, larger Dynamic Type") was not performed — there is no
  simulator or screen available in this environment. The design follows
  `DESIGN_LANGUAGE.txt` (semantic system colors throughout for automatic
  dark mode, system fonts which scale with Dynamic Type by default,
  accessibility labels on key elements), but has not been visually
  inspected.
- **VoiceOver** labels were added throughout but not tested with an actual
  screen reader.
- **Performance** at scale (thousands of expenses) was not profiled.

## Recommended next step

Open the project in Xcode (`BUILD_AND_INSTALL.md`), run `Product → Build`
then `Product → Test`, and report back anything that doesn't compile or
any test that fails — given the size of this codebase, that feedback loop
should be fast to close.
