Run SwiftLint on the iOS project and report results.

```bash
swiftlint --reporter emoji
```

If SwiftLint is not installed:
```bash
brew install swiftlint && swiftlint --reporter emoji
```

After running, report:
- Total violations (errors + warnings)
- List of errors (if any) — these must be fixed before merging
- List of warnings (summarized by rule if > 10)
- Files with the most violations

If there are errors, explain each one and suggest a fix.
If there are zero violations, confirm the project is lint-clean.
