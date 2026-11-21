# ENGINEERING RULES: AITR Food Booking (read before every task)

## Product
Real campus food-ordering business app. Roles: Customer (default), Vendor, Delivery Partner. Modules: Food (live), Bus and Stationery (placeholders; stationery items/orders are only seeded demo data).

## Architecture (strict)
- Feature-first under `lib/features/<feature>/` using the project's existing sub-folders (models, providers, screens, widgets, services, data). Shared code in `lib/core/`. Do not reorganize existing folders.
- Layers: Widget → Provider (ChangeNotifier) → Repository (abstract interface) → implementation (`InMemory*` today, a backend later). Providers receive repositories through the constructor. Widgets never contain business logic.
- Domain services (pricing, batching, suggestions, status transitions) are pure Dart: no Flutter imports, deterministic (inject the clock), unit-testable.
- SERVER-AUTHORITATIVE RULE: totals, fees, discounts, order IDs and status transitions are computed/validated in the repository/domain layer from catalog and location data. Never trust numbers supplied by the UI. The UI only displays.
- Repositories expose `Stream<List<T>>` for live data (orders, menu, feedback) so a backend can replace them without UI changes. In-memory streams must emit the current value first, then updates.
- Do not store orders inside `CheckoutProvider`. Orders live in `OrderRepository`.

## Money and time
- Money = `int` rupees; display only via `formatRupees(int)`. Never `double` for money (the tax rate is the only double; always `.round()`).
- All constants in `lib/core/config/app_config.dart`. No magic numbers in widgets or providers.
- Services/repositories take an injected clock (`DateTime Function() now`). "Today" = device-local calendar day.

## Order lifecycle (single source of truth, enforced in `OrderStatus.isTransitionAllowed(from, to, actor)`)
| From | To | Allowed actor |
|---|---|---|
| placed | accepted | vendor |
| placed | cancelled | customer, vendor |
| accepted | preparing | vendor |
| accepted | cancelled | vendor |
| preparing | readyForPickup | vendor |
| preparing | cancelled | vendor |
| readyForPickup | outForDelivery | deliveryPartner |
| outForDelivery | delivered | deliveryPartner |
Anything else is rejected with a `StateError` and covered by tests.

## Roles and access
`UserRole { customer, vendor, deliveryPartner }`. Vendor/Delivery screens are reachable only after `RoleAccessService` verification. Demo mode uses invite codes; a backend must grant roles server-side. Vendors read/modify only their own `vendorId` items and orders. Delivery partners see only the 3 allowed fields.

## Privacy and security
- Never store, print or log card data. No PII in logs (use `AppLogger`). No secrets or API keys in code.
- The word "Zone" never appears in user-visible text (UI, tooltips, semantics, errors).
- Delivery order cards and notifications show only Address, In-Time, Item (plus action buttons). No prices, names or phone numbers.

## UX robustness
- Every async action has loading, error (friendly message + retry) and empty states. No unhandled exceptions. After any `await`, check `mounted`. Cancel timers, subscriptions and controllers in `dispose`.
- Prevent double submission (disable the button AND use an idempotency key).
- Forms validate after first interaction and on submit; correct keyboard types. No overflow at 320px width and text scale 1.3.

## Performance
- Lazy lists/grids (`builder` constructors, stable `ValueKey`s). `const` constructors wherever possible.
- Rebuild only what changed: `context.select`, `Selector`, small `Consumer`s. No heavy work in `build()`: precompute in providers and cache until inputs change.
- Network images: set `cacheWidth`/`cacheHeight` to display size. `RepaintBoundary` around the interactive map and animated widgets. No unbounded timers.

## Testing
Table-driven unit tests for domain services and repositories. Write only the tests each prompt lists. Existing tests (`customer_profile_test.dart`, `profile_screen_test.dart`) must stay green.

## Demo data
All seeded sample data lives in ONE file, `lib/core/demo/demo_seeder.dart`, guarded by `AppConfig.kDemoMode`, so production can delete it cleanly.

## Credit rules (every prompt)
- No plan or walkthrough artifacts, no screenshots, no browser/emulator runs, no extra docs.
- Don't re-read files already read. Grep to locate. Small targeted edits; create whole files only when new.
- Run `flutter analyze` ONCE and `flutter test` ONCE at the end; fix errors only; after 2 failed fixes stop and report the exact error.
- Final reply max 8 lines. One git commit with the message given in the prompt. `main.dart` and `lib/previews.dart` must always compile.