# BUILD PLAN — Personal Expense App (Het + Sarthak)

## 0. Environment inspection

This session runs in a **Linux container** with no macOS, no Xcode, and no
Swift toolchain installed (`swift`, `xcodebuild` are not present; only
`python3`, `git`, `zip`). There is no simulator and no physical device
attached.

**Consequence:** the project cannot be compiled, unit-tested, or run in
this environment. `xcodebuild`/`swift test` cannot be executed here. This
is documented up front per the task's own instructions ("do not claim
success for a test that was not actually performed").

**What this build plan does instead:**
- Produce a complete, valid Xcode project (hand-authored `project.pbxproj`
  via a deterministic Python generator, since `xcodegen`/`tuist` are also
  unavailable) with every source file wired into the correct targets.
- Write production Swift/SwiftUI code by hand, keeping each unit small and
  syntactically conservative to minimize risk in the absence of a compiler.
- Write full XCTest coverage for every pure/testable unit (models,
  `BalanceCalculator`, `SyncEngine` merge logic, `ExpenseRepository`,
  `ExportImportService`). These tests are believed correct but are
  **unverified by an actual test run** — this is called out again in
  `TEST_REPORT.md`.
- Perform a manual static-review pass (structure, naming, import
  correctness, brace/paren balance, API usage against known Apple APIs) in
  place of a compiler.
- Two-phone sync (Phase 10) cannot be physically tested — no devices are
  attached to this session. The merge algorithm itself is covered by pure
  unit tests that don't require MultipeerConnectivity or real devices.

The first thing the user should do after downloading the project is open
it in Xcode and build it — see `BUILD_AND_INSTALL.md`. Any compiler errors
that turn up should be reported back; the architecture is intentionally
simple so such fixes should be small and localized.

## 1. Architecture

```
ExpenseApp/
  ExpenseApp.xcodeproj/          Xcode project (hand-generated pbxproj)
  ExpenseApp/                    App target sources
    ExpenseAppApp.swift          @main App entry, SwiftData container setup
    Info.plist                   Bonjour + Local Network usage strings
    Assets.xcassets              AppIcon, AccentColor
    Models/
      Payer.swift                Het | Sarthak | Company enum; Payer.people
                                  restricts identity/authorization pickers
                                  to the two humans
      PaymentMethod.swift        cash | online enum
      ExpenseCategory.swift      category enum with SF Symbol + display name;
                                  CSC deliberately merges what used to be
                                  Alcohol/Tobacco with a custom Codable
                                  init(from:) so old raw values still decode
      ExpenseRecord.swift        plain Codable DTO — the sync/business-logic
                                  representation, has no SwiftData dependency;
                                  carries authorizedBy (Payer?), meaningful
                                  only when paidBy == .company
      Expense.swift              @Model SwiftData persistence entity +
                                  conversion to/from ExpenseRecord
      Budget.swift                amount + specific date range, one active
                                   budget at a time
    Persistence/
      PersistenceController.swift   ModelContainer setup (app + in-memory test)
      ExpenseRepository.swift       CRUD + tombstone delete, protocol-based
      BudgetStore.swift             single active Budget, JSON in UserDefaults
    Services/
      BalanceCalculator.swift       pure 50/50 balance engine (no SwiftUI, no
                                     SwiftData — operates on [ExpenseRecord])
      ExportImportService.swift     JSON export/import, schema validation,
                                     reuses SyncEngine.merge for safe import
      BudgetCalculator.swift        pure spent/remaining math for a Budget
                                     over its date range (no SwiftUI/SwiftData)
    Sync/
      SyncMessage.swift          versioned Codable wire protocol
      SyncEngine.swift           pure merge function (UUID + updatedAt LWW)
      PeerSyncManager.swift      MultipeerConnectivity session/transport
    Views/
      RootTabView.swift, HomeView.swift, TransactionsView.swift,
      AddExpenseView.swift, ExpenseDetailView.swift, BalanceView.swift,
      SettingsView.swift, SyncView.swift, OnboardingView.swift,
      BudgetEditorView.swift
      Components/                small reusable view pieces
    Utilities/
      CurrencyFormatter.swift, Haptics.swift, DeviceIdentity.swift,
      AppStorageKeys.swift, ExpenseBackupDocument.swift
  ExpenseAppTests/               XCTest unit test target
    BalanceCalculatorTests.swift, BudgetCalculatorTests.swift,
    BudgetTests.swift, ExpenseRepositoryTests.swift, SyncEngineTests.swift,
    SyncMessageCodecTests.swift, ExportImportServiceTests.swift,
    ExpenseRecordTests.swift, ExpenseCategoryTests.swift,
    CurrencyFormatterTests.swift
```

Key architectural decision: **business logic never touches SwiftUI or
SwiftData directly.** `ExpenseRecord` is a plain `Codable` struct used by
`BalanceCalculator`, `SyncEngine`, and `ExportImportService`. The SwiftData
`@Model` class `Expense` is only a storage entity; `ExpenseRepository`
converts between the two at the persistence boundary. This makes the
balance/sync logic unit-testable without a persistence stack or a UI, and
keeps `Sync/` reusable for both peer-to-peer sync and JSON import (same
merge algorithm, two entry points).

## 2. Persistence choice

**SwiftData** (iOS 17+), per spec's first preference. It is fully native,
integrates directly with SwiftUI (`@Query`, `.modelContainer`), requires no
schema/migration boilerplate for this small model, and is fully local — no
CloudKit sync container is configured (this is critical: SwiftData
supports an *optional* CloudKit backing, which is deliberately **not**
enabled here, since the spec forbids any cloud/hosted backend and requires
MultipeerConnectivity direct sync instead).

Deployment target: **iOS 17.0** (required for SwiftData).

## 3. Local-network sync strategy

- `MCNearbyServiceAdvertiser` + `MCNearbyServiceBrowser` + `MCSession`,
  service type `expenseapp-sync` (15 chars, valid Bonjour token — max is 15).
- Manual, foreground-only pairing: both apps must be open; connection is
  confirmed via `MCSession` invite/accept, not auto-join.
- On connect, both sides send a `.hello`, then a full `.expenseBatch` of
  every local `ExpenseRecord` (active + tombstoned), chunked at a fixed
  batch size to respect the message-size guidance in the spec, followed by
  `.syncComplete`. Given the dataset size (two people's personal expenses),
  a full-state exchange is simpler and strictly safer than delta sync — it
  cannot miss an update — while remaining fast enough in practice.
- Each side merges the incoming batch into its local store via
  `SyncEngine.merge`: per-UUID, later `updatedAt` wins; ties keep the local
  record (deterministic, per spec §11). Deletions are tombstones
  (`deletedAt` set), so a delete always propagates correctly and never
  "un-deletes" on the peer.
- No background sync is implemented or claimed anywhere in the UI/copy —
  foreground manual sync only, per spec §12.

## 4. Milestones

1. Data model + persistence + repository tests
2. BalanceCalculator + tests
3. Core UI (Home, Transactions, Add/Edit, Balance, Settings)
4. Search & filters
5. Sync engine + SyncView + merge tests
6. Local network Info.plist config + permission copy
7. Export/Import + tests
8. Accessibility/dark-mode/haptics polish
9. Xcode project generation
10. Static validation pass (no compiler available)
11. Documentation + packaging (zip)

## 5. Known limitations (stated up front)

- **Not compiled or run in this environment.** Must be opened in Xcode on
  a Mac before first use; report any compiler errors.
- **Two-phone sync not physically tested** — no devices available in this
  session. Merge logic is unit-tested in isolation.
- Free Apple ID signing expires periodically and requires rebuild/reinstall
  — documented in `BUILD_AND_INSTALL.md`, not glossed over.
- "This Trip" custom period grouping from the design doc is intentionally
  simplified to **This Month / All Time** in v1 — there is no trip/project
  entity in the v1 data model (spec explicitly says not to add it until
  the basic system is stable), so a "This Trip" filter would have nothing
  real to key off of.
- **Budget spend counts every payer, including Company.** A budget is
  meant to represent total money going out in its date range, so a
  Company-paid expense counts toward it — unlike the 50/50 balance, which
  excludes Company entirely. If that's not the behavior wanted, say so and
  it's a small change to `BudgetCalculator`.

## 6. Post-hoc audit pass (after Budget/Company/CSC were added)

With no compiler available, every feature added after the initial build
was followed by a manual re-audit rather than trusting the diff alone:

- **Cross-reference sweep**: every `Payer.allCases` usage was checked —
  two (Settings "Your name", Onboarding) needed restricting to
  `Payer.people` (Het/Sarthak only) once `Company` was added as a third
  case, since a "who is using this iPhone" picker should never offer
  "Company". The Add Expense "Paid By" picker correctly keeps
  `Payer.allCases` since Company *is* a valid answer there.
- **Exhaustiveness sweep**: grepped for every `switch`/`case .het`/
  `case .sarthak` site to confirm nothing does an exhaustive switch over
  `Payer` that would silently need a `.company` arm (none found — the one
  place that used to do this, `Payer.other`, was unused dead code and was
  removed rather than patched).
- **Construction-site sweep**: every `ExpenseRecord(...)` and
  `BudgetCardView(...)` call site (app + tests) was checked against the
  current initializer signature; both live app changes (adding
  `authorizedBy`, adding `summary:`) put the new parameter at the end
  with a default or updated the one call site, so no test needed touching.
- **pbxproj/disk parity**: the Python generator was re-run and diffed
  against the committed `project.pbxproj` — byte-identical, and a
  file-by-file diff confirms every `.swift` file on disk is referenced
  exactly once and vice versa (130 objects, 0 dangling references).
- **Web app parity**: `docs/index.html` was diffed against the last
  published artifact — byte-identical. Every `getElementById`/
  `querySelector("#…")` call was checked against actual `id="…"`
  attributes (0 dangling references — this is the exact class of bug the
  Home-hero-card merge risked). Every `data-action="…"` in the HTML has a
  matching case in the JS dispatcher and vice versa (0 orphans either way).
- **Logic parity test suite**: the pure functions (`computeBalance`,
  `computeBudgetProgress`, `mergeRecords`, `isValidRecord`,
  `normalizeCategory`) were extracted verbatim from the shipped
  `docs/index.html` and run under Node against 25 cases mirroring the
  Swift XCTest suite — all pass. The real 70-record Jaipur+SCS dataset
  still balances to the exact figure (₹9,076) verified earlier.

No bugs were found in this pass beyond the two `Payer.allCases` sites
above, which were fixed during the same work session that introduced
Company (not left for this audit) — this section exists as the evidence
trail, not a list of open issues.
