# App Mode Switching Scripts

These scripts make it easy to switch between debug and production modes for development and App Store screenshots.

## Available Scripts

### `switch_to_debug.sh`

Switches to full debug mode with all development features enabled:

- ✅ Debug logging enabled
- ✅ Debug UI visible
- ✅ Endpoint failure simulation enabled
- ✅ All development tools available

### `switch_to_production.sh`

Switches to production-like mode for App Store screenshots:

- ❌ Debug logging disabled
- ❌ Debug UI hidden
- ❌ Endpoint failure simulation disabled
- ✅ Clean, production-like appearance

### `check_mode.sh`

Shows the current mode and configuration status.

## Usage

```bash
# Switch to debug mode
./scripts/switch_to_debug.sh

# Switch to production mode (for screenshots)
./scripts/switch_to_production.sh

# Check current mode
./scripts/check_mode.sh
```

## What the Scripts Do

Each script automatically:

1. 📝 Updates the debug configuration file
2. 🧹 Cleans the Flutter project
3. 📦 Gets Flutter dependencies
4. 🍎 Installs CocoaPods dependencies
5. ✅ Prepares the project for the selected mode

## App Store Screenshots

For App Store screenshots:

1. Run `./scripts/switch_to_production.sh`
2. Build and run in Xcode
3. Take your screenshots
4. Run `./scripts/switch_to_debug.sh` to return to development

## Notes

- Production mode in simulator uses debug build with production-like behavior
- True production builds (`flutter run --release`) only work on physical devices
- The scripts handle all necessary cleanup and dependency installation
- No need to remember multiple commands - just run the appropriate script!
