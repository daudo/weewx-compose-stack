# Extension Patches Template

This directory contains example patches for WeeWX extensions using the enhanced patch management system.

## Patch Structure

Each patch file should include:
1. **Comprehensive header** with issue description, error messages, fix explanation, and references
2. **Standard diff format** generated with `diff -u original.py modified.py`
3. **Descriptive filename** following the pattern `XX-fix-description.patch`

## Example Patch Format

```patch
# Brief Description of Fix
#
# Issue: Detailed description of the problem
# Error: Exact error message (if applicable)
# 
# Fix: Explanation of the solution
# Location: File and line number information
# Affects: What functionality is impacted
#
# References:
# - Relevant documentation links
# - Bug report URLs
#
--- path/to/original/file.orig    timestamp
+++ path/to/modified/file         timestamp
@@ line_numbers @@
 context_line
-old_content
+new_content
 context_line
```

## Patch Management Best Practices

### Naming Convention
- Use numerical prefixes for application order: `01-`, `02-`, `03-`
- Use descriptive names: `01-fix-python313-compat.patch`
- Keep names concise but informative

### Documentation
- **Always** include comprehensive header comments
- Explain the underlying issue, not just the fix
- Include error messages and relevant context
- Link to official documentation or bug reports

### Dependencies and Ordering
- Consider line number impacts between patches
- Apply patches in logical dependency order
- Test patch application sequence thoroughly
- Document any ordering requirements in README.md

### Testing
```bash
# Test individual patches (dry run)
patch -p0 --dry-run < 01-example-fix.patch

# Test patch sequence
cp target/file.py target/file.py.orig
patch -p0 < 01-example-fix.patch
patch -p0 < 02-additional-fix.patch
```

## Hybrid Approach

The enhanced patch system supports:

1. **Patch files** for code modifications (preferred for upstream fixes)
2. **Simple file operations** for additions/corrections (copying missing files, etc.)

### When to Use Patch Files
- Fixing bugs in existing code
- Compatibility updates (Python version changes)
- Security fixes
- Performance improvements

### When to Use File Operations
- Adding missing files from archives
- Copying configuration templates
- Creating directories
- Simple file corrections

## Contributing New Patches

1. Create descriptive patch with comprehensive header
2. Test patch application in isolation and sequence
3. Update this README.md with patch details
4. Consider impact on existing patches (line numbers)
5. Follow the established naming convention

## Maintenance

- Keep patches focused on single issues
- Update documentation when patches are modified
- Test patch compatibility with extension updates
- Remove obsolete patches when upstream fixes are available