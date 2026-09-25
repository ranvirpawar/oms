# OMS coding-agent entry point

## Scope and authority
- Read [docs/INDEX.md](docs/INDEX.md), then only the relevant module and canonical source.
- **Current implementation:** repository code is authoritative; verify the cited source before editing.
- **Product intent:** the 21 decisions in [BUSINESS_RULES.md](docs/BUSINESS_RULES.md) are authoritative for their clarified meanings. Do not ask them again.
- **Future behavior:** implement only explicit requirements. Unestablished behavior is Unknown or Deferred.
- Documentation accelerates retrieval; it does not replace source verification.

## Default change contract
- Existing OMS behavior is working and intentional unless the task explicitly requests a change.
- Before editing, determine: requested behavior; behavior to preserve; required files; smallest scoped change.
- Do not opportunistically refactor, modernize architecture, replace libraries, rename APIs/fields, normalize backend casing, or redesign workflows.
- Record out-of-scope observations in [KNOWN_GAPS.md](docs/KNOWN_GAPS.md); do not fix them without scope.
- Preserve shared barcodes across tube types and intentional extra tubes.
- Preserve backend spellings such as `PatientCOunt`, `HanoverUserid`, and endpoint-specific ID casing.
- Use local IST behavior. Do not introduce timezone normalization.
- Tests are expected when modifying modules: appropriate unit, logic, and workflow coverage using existing patterns.

## Baseline and exclusions
- Dev is the working baseline: `lib/dev_main.dart`; same code/features are used across flavors.
- Active architecture: GetX views/controllers/bindings -> feature services -> shared Dio APIClient.
- **Do not work on `lib/migration`. Keep it untracked and out of scope. Do not design features around BLoC/migration.**
- Production bootstrap observations are not authorization to change development behavior.
- Supported targets: Android and iOS only. Web/desktop directories are scaffolding.
- Recollection is incomplete/future functionality; do not expand it without a requirement.
- Notifications/background processing are not implemented.
- Runner TAT development and deeper DISHA recovery are deferred.
- Skip generated files, build output, dependencies, and caches unless directly relevant.

## Retrieval
- [INDEX](docs/INDEX.md): task routing and source map.
- [BUSINESS_RULES](docs/BUSINESS_RULES.md): complete product decisions C01-C21.
- [KNOWN_GAPS](docs/KNOWN_GAPS.md): source/intent differences and action status.
- [TESTING](docs/TESTING.md): tests to add and existing seams.
