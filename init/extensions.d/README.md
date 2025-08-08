# WeeWX Extensions Directory

This directory contains modular scripts for installing, patching, and configuring WeeWX extensions and skins using a 3-phase architecture.

## Architecture Overview

Extensions use a structured 3-phase approach:

```
extensions.d/
├── extension-name/
│   ├── 0_install.sh    # Install the extension
│   ├── 1_patch.sh      # Apply patches/fixes (optional)
│   └── 2_configure.sh  # Configure with environment variables
├── templates/          # Template scripts for creating new extensions
```

## How It Works

The main `install-extensions.sh` script automatically:

1. **Discovers extension directories** (excludes `templates/`)
2. **Processes each extension in 3 sequential phases**: install → patch → configure
3. **Provides clear error handling** and logging for each phase

## Current Extensions

- **belchertown/** - Modern responsive web skin
- **gw1000/** - Ecowitt GW1000/WS3800 weather station driver
- **inigo/** - weeWXWeatherApp Android app support

Extensions are processed alphabetically by directory name, with each extension running through all 3 phases before the next extension starts.

**Processing Order**: If specific ordering is needed (e.g., hardware drivers before skins), directory names can be prefixed with numbers: `0_gw1000`, `1_belchertown`, `2_inigo`.

## Adding New Extensions

1. Create a new directory: `extensions.d/my-extension/`
2. Copy templates from `examples/extensions.d/` (see project root)
3. Customize each phase script:

### Phase 0: Installation (`0_install.sh`)
```bash
#!/bin/bash
set -e

EXTENSION_VERSION=${EXTENSION_VERSION:-1.0.0}
ENABLE_EXTENSION=${ENABLE_EXTENSION:-true}

# Skip if disabled
if [ "$ENABLE_EXTENSION" != "true" ]; then
    return 0 2>/dev/null || exit 0
fi

# Installation logic here...
weectl extension install "$EXTENSION_URL" --config=/data/weewx.conf --yes
```

### Phase 1: Patching (`1_patch.sh`) 
```bash  
#!/bin/bash
set -e

# Apply fixes for upstream bugs
# Copy missing files, apply compatibility patches, etc.
```

### Phase 2: Configuration (`2_configure.sh`)
```bash
#!/bin/bash
set -e

# Configure using environment variables and weewx_config_api
/init/weewx_config_api.py set-value "[Section]" "key" "$ENVIRONMENT_VAR"
```

## Templates Directory

The `examples/extensions.d/` directory (in project root) contains starter scripts that you can copy and customize:

- **`0_install.sh`** - Template for extension installation logic
- **`1_patch.sh`** - Template for applying patches and fixes  
- **`2_configure.sh`** - Template for environment-driven configuration

**Usage:**
1. Copy the template scripts from `examples/extensions.d/` to your new extension directory
2. Customize the environment variables and logic for your extension
3. Make scripts executable: `chmod +x extension-name/*.sh`

## Benefits of 3-Phase Architecture

### ✅ **Separation of Concerns**
- **Install**: Pure extension installation logic
- **Patch**: Fix upstream bugs independently  
- **Configure**: Environment-driven setup

### ✅ **Better Maintainability**
- **Easier debugging**: Test each phase independently
- **Clearer code**: Single responsibility per script
- **Easier updates**: Modify only relevant phase

### ✅ **Scalability**
- **Consistent pattern**: All extensions follow same structure
- **Predictable**: Always know where to find install/patch/config logic
- **Flexible**: Phases can be skipped if not needed

## Testing

To test an individual extension:

```bash
# Test specific phase
ENABLE_EXTENSION=true bash extensions.d/extension-name/0_install.sh

# Test entire extension with environment variables  
ENABLE_EXTENSION=true EXTENSION_VERSION=1.0.0 bash install-extensions.sh
```