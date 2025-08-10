# Belchertown Patches

This directory contains patches that fix upstream bugs and compatibility issues in the Belchertown skin.

## Patches Overview

| Patch | Description | Issue | Affected Lines |
|-------|-------------|-------|----------------|
| `01-fix-locale-python313-compat.patch` | Python 3.13 locale compatibility | `locale.format()` removed | ~15 |

## Patch Details

### 01-fix-locale-python313-compat.patch

**Issue**: Python 3.13 removed the `locale.format()` method in favor of `locale.format_string()`.

**Error**:

```
AttributeError: module 'locale' has no attribute 'format'
```

**Fix**: Adds a monkeypatch after the locale import to restore compatibility:

```python
locale.format = locale.format_string  # Python 3.13 compatibility
```

**Impact**: All currency and number formatting in Belchertown skin.

**References**:

- [Python 3.13 What's New](https://docs.python.org/3.13/whatsnew/3.13.html#locale)

## Application Order

Patches are applied in numerical order:

1. `01-fix-locale-python313-compat.patch` - Applied first (affects early imports)

## Testing

To verify patches apply correctly:

```bash
# Test individual patches (dry run)
patch -p0 --dry-run < 01-fix-locale-python313-compat.patch

# Test in sequence (as applied by patch script)
cp bin/user/belchertown.py bin/user/belchertown.py.orig
patch -p0 < 01-fix-locale-python313-compat.patch

```

## Contributing

When adding new patches:

1. Use descriptive filenames: `XX-fix-description.patch`
2. Add comprehensive header comments explaining the issue
3. Update this README.md
4. Test patch application order
5. Consider line number impacts on subsequent patches
