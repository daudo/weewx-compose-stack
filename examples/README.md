# Examples Directory

This directory contains example files and templates to help you extend the WeeWX Docker setup.

## Extension Templates (`extensions.d/`)

The `extensions.d/` directory contains template scripts for creating new WeeWX extensions using our 3-phase architecture:

- **`0_install.sh`** - Template for extension installation logic
- **`1_patch.sh`** - Template for applying patches and fixes  
- **`2_configure.sh`** - Template for environment-driven configuration

### Usage

1. Copy the template scripts to your new extension directory in `init/extensions.d/my-extension/`
2. Customize the environment variables and logic for your extension
3. Make scripts executable: `chmod +x init/extensions.d/my-extension/*.sh`

### Template Structure

```
examples/
└── extensions.d/
    ├── 0_install.sh    # Extension installation template
    ├── 1_patch.sh      # Patching and fixes template
    └── 2_configure.sh  # Configuration template
```

For detailed documentation on the 3-phase extension architecture, see `init/extensions.d/README.md`.