# Fraction Sprint

A zetamac-style speed drill for fractions, for quant interview prep. Pick your problem types and number
ranges, hit Start, and answer as many as you can before the timer runs out. The next problem appears
as soon as your answer is right.

- Add, subtract, multiply and divide fractions; fraction ↔ decimal conversions
- Configurable numerator/denominator ranges, proper-fractions-only, lowest-terms-only
- 30s / 1 min / 2 min / 5 min runs
- On-device history with best score, recent average and a score chart per settings combination
- No account, no ads, no network access

## Layout

| Path | What |
| --- | --- |
| `Packages/FractionCore` | Pure Swift logic: `Fraction`, answer parsing, problem generator, game engine, history stats. Unit tested. |
| `FractionSprint/` | SwiftUI app (iOS 17+, iPhone). |
| `project.yml` | XcodeGen spec; the `.xcodeproj` is generated, not committed. |
| `.github/workflows/ci.yml` | Tests + simulator build on every push. |
| `.github/workflows/testflight.yml` | Manual: signed archive uploaded to App Store Connect / TestFlight. |
| `docs/privacy.md` | Privacy policy linked from the App Store listing. |

## Develop on a Mac

```sh
brew install xcodegen
xcodegen generate
open FractionSprint.xcodeproj
swift test --package-path Packages/FractionCore
```

## Release

1. Add repository secrets `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`
   (App Store Connect API key with the Admin role, so Xcode can create signing certificates in the cloud).
2. Actions → TestFlight → Run workflow, with the marketing version.
3. The build appears in App Store Connect → TestFlight after processing (about 10–30 minutes).
