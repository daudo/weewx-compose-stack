# Examples Directory

This directory contains example files and templates to help you extend the WeeWX Docker setup.

## Extension Templates (`extensions.d/`)

The `extensions.d/` directory contains template scripts for creating new WeeWX extensions using our 3-phase architecture with hybrid patching approach:

- **`0_install.sh`** - Template for extension installation logic
- **`1_patch.sh`** - Template for applying patches using hybrid approach (patch files + file operations)
- **`2_configure.sh`** - Template for environment-driven configuration
- **`patches/`** - Directory containing example patch files for code modifications

### Enhanced Patch Management System

The patch system includes intelligent handling with comprehensive error detection:

- **Automatic ordering** - Patches applied in numerical order
- **Dry-run testing** - Validates patch compatibility before application
- **Conflict detection** - Identifies already applied or conflicting patches
- **Comprehensive documentation** - Each patch includes detailed headers explaining issue and fix
- **Consistent logging** - Uses common.sh logging functions for visual status reporting

#### Hybrid Patching Approach

We use a hybrid approach for handling extension fixes:

- **Code modifications** → Use `.patch` files
- **File additions/corrections** → Use simple file operations (copying missing files, etc.)

### Usage

1. Copy the template scripts to your new extension directory in `init/extensions.d/my-extension/`
2. **All scripts automatically source `common.sh`** for shared utilities and consistent logging
3. For code changes:
   - Create proper diff patches and put them in `init/extensions.d/my-extension/patches/`
   - Use `diff -u original.py modified.py > patches/01-description.patch`
4. For file operations:
   - Customize the file handling functions in `1_patch.sh`
5. Customize environment variables and configuration logic
6. Make scripts executable: `chmod +x init/extensions.d/my-extension/*.sh`

### Common.sh Utilities

All extension scripts have access to shared functions from `init/common.sh`:

#### Logging Functions

- `log_info "message"` - ℹ Informational messages (blue icon)
- `log_success "message"` - ✓ Success confirmations (green checkmark)  
- `log_warning "message"` - ⚠ Non-critical warnings (yellow warning)
- `log_error "message"` - ✗ Errors and failures (red X, outputs to stderr)

#### Patch Management

- `apply_patch_files()` - Enhanced patch application with ordering and conflict detection

#### Configuration Backup

- `manage_backups init|cleanup|restore|all` - Backup management operations

### Template Structure

```
examples/
└── extensions.d/
    ├── 0_install.sh              # Extension installation template
    ├── 1_patch.sh                # Hybrid patching template
    ├── 2_configure.sh            # Configuration template
    └── patches/
        └── 01-example-fix.patch  # Example patch file
```

### Creating Patch Files

To create a patch file for code modifications:

1. **Make a copy of the original file:**

   ```bash
   cp bin/user/extension.py bin/user/extension.py.orig
   ```

2. **Edit the file with your changes:**

   ```bash
   # Make your modifications to bin/user/extension.py
   ```

3. **Create the patch with comprehensive header:**

   ```bash
   # Create patch with descriptive header (see patches/README.md for format)
   diff -u bin/user/extension.py.orig bin/user/extension.py > patches/01-my-fix.patch
   # Edit the patch file to add comprehensive header comments
   ```

4. **Verify the patch:**

   ```bash
   patch -p0 --dry-run < patches/01-my-fix.patch
   ```

5. **Test with the enhanced patch system:**

   ```bash
   # The system will automatically handle ordering, dry-run testing, and conflict detection
   bash 1_patch.sh
   ```

#### Patch Documentation Requirements

Each patch must include a comprehensive header with:

- Issue description and error messages
- Fix explanation and affected functionality
- Location information (file/line numbers)
- References to documentation or bug reports

See `patches/README.md` for detailed patch format guidelines and best practices.

### Benefits

- **Reviewable**: Patch files can be easily reviewed and understood
- **Maintainable**: Updates are clear and trackable
- **Standard**: Uses industry-standard diff/patch format
- **Flexible**: Combines patch files with simple file operations as needed

For detailed documentation on the 3-phase extension architecture, see `init/extensions.d/README.md`.