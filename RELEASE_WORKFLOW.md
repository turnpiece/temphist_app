# Release Workflow Guide

This document outlines the recommended workflow for creating releases of the Temphist App.

## Overview

The app uses environment variables to automatically switch between debug and production configurations based on the Flutter build mode. This eliminates the need to manually modify configuration files during releases.

## Key Changes from Previous Workflow

- **No more manual file modifications**: The app automatically uses the correct configuration based on build mode
- **Automatic version management**: The release script handles version bumping and tagging
- **Cleaner git history**: No more commits that only change build configuration

## Recommended Release Workflow

### 1. Development Phase

```bash
# Work on the develop branch
git checkout develop
# Make your changes, test thoroughly
git add .
git commit -m "Your feature description"
git push origin develop
```

### 2. Merge to Main

```bash
# Switch to main and merge develop
git checkout main
git pull origin main
git merge develop
git push origin main
```

### 3. Create Release

```bash
# Use the release script to create a new release
./scripts/create_release.sh patch    # For bug fixes (1.0.0 -> 1.0.1)
./scripts/create_release.sh minor    # For new features (1.0.0 -> 1.1.0)
./scripts/create_release.sh major    # For breaking changes (1.0.0 -> 2.0.0)
./scripts/create_release.sh custom 1.2.3  # For specific version
```

### 4. Build for Distribution

```bash
# Build for different platforms
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web
```

## Release Script Features

The `create_release.sh` script automatically:

- ✅ Validates you're on the main branch
- ✅ Checks for uncommitted changes
- ✅ Warns if develop isn't merged
- ✅ Updates version in `pubspec.yaml`
- ✅ Increments build number
- ✅ Creates git tag with release notes
- ✅ Pushes changes and tags to remote

## Build Configuration

The app automatically uses the correct configuration:

- **Debug builds** (`flutter run --debug`): Uses debug configuration with all debug features enabled
- **Release builds** (`flutter build --release`): Uses production configuration with debug features disabled

## Version Numbering

We use semantic versioning (SemVer):

- **Major** (X.0.0): Breaking changes
- **Minor** (X.Y.0): New features, backward compatible
- **Patch** (X.Y.Z): Bug fixes, backward compatible

Build numbers increment with each release for app store requirements.

## Testing Before Release

Always test both configurations:

```bash
# Test debug configuration
flutter run --debug

# Test production configuration
flutter run --release
```

## Rollback Procedure

If you need to rollback a release:

```bash
# Find the previous tag
git tag --list

# Reset to previous version
git reset --hard <previous-tag>
git push --force origin main

# Delete the problematic tag
git tag -d <problematic-tag>
git push origin :refs/tags/<problematic-tag>
```

## Troubleshooting

### "Working directory has uncommitted changes"

- Commit or stash your changes before creating a release
- The release script requires a clean working directory

### "You must be on the main branch"

- Switch to main branch: `git checkout main`
- The release script only works from the main branch

### "Develop branch is not merged"

- Merge develop into main first: `git merge develop`
- Or continue anyway if you intentionally want to release without latest develop changes

## Environment Variables

You can manually override the build configuration:

```bash
# Force debug mode in any build
flutter run --dart-define=DEBUG=true

# Force production mode in any build
flutter run --dart-define=DEBUG=false
```

## Legacy Scripts

The old switch scripts (`switch_to_debug.sh` and `switch_to_production.sh`) are now informational only. They no longer modify files but provide guidance on how to build in different modes.

## Best Practices

1. **Always test thoroughly** on both debug and release configurations
2. **Use semantic versioning** consistently
3. **Write clear commit messages** for better release notes
4. **Tag releases immediately** after merging to main
5. **Keep develop branch up to date** with main after releases
6. **Document breaking changes** in release notes
