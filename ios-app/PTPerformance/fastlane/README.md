fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios beta_manual

```sh
[bundle exec] fastlane ios beta_manual
```

Push to TestFlight using manual certificates

### ios beta_auto

```sh
[bundle exec] fastlane ios beta_auto
```

Push to TestFlight with Xcode automatic signing (simplest)

### ios beta_simple

```sh
[bundle exec] fastlane ios beta_simple
```

Simple build and upload (uses project's existing signing config)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
