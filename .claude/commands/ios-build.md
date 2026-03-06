Build the iOS app for the simulator and optionally install it.

Run the local build script:

```bash
cd ios-app && bash build_local.sh $ARGUMENTS
```

If `ios-app/build_local.sh` doesn't exist, fall back to:

```bash
xcodebuild build \
  -scheme pt-performance \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath build/DerivedData \
  | xcpretty --color 2>/dev/null || cat
```

After a successful build, report:
- Build status (succeeded / failed)
- App path: `build/DerivedData/Build/Products/Debug-iphonesimulator/pt-performance.app`
- Any warnings count

If the build fails, show the first 20 error lines and suggest the most likely fix.
