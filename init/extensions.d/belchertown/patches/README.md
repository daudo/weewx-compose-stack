# Belchertown Patches

This directory contains patches that fix upstream bugs and compatibility issues in the Belchertown skin.

## Patches Overview

| Patch | Description | Issue | Affected Lines |
|-------|-------------|-------|----------------|
| `01-fix-locale-python313-compat.patch` | Python 3.13 locale compatibility | `locale.format()` removed | ~15 |
| `02-fix-regex-escape-sequences.patch` | Fix regex escape sequence warnings | SyntaxWarning in Python 3.13 | ~1680 |

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

### 02-fix-regex-escape-sequences.patch

**Issue**: Python 3.13 shows SyntaxWarning for invalid escape sequences in regex strings.

**Warning**:

```
/data/bin/user/belchertown.py:1680: SyntaxWarning: invalid escape sequence '\.'
  "(?P<distance>[0-9]*\.?[0-9]+) km(?P<rest>.*)$",
```

**Fix**: Changes regular string to raw string for regex pattern:

```python
# Before:
"(?P<distance>[0-9]*\\.?[0-9]+) km(?P<rest>.*)$"
# After:
r"(?P<distance>[0-9]*\.?[0-9]+) km(?P<rest>.*)$"
```

**Impact**: Earthquake distance parsing and unit conversion.

**Background**: Raw strings (`r"..."`) treat backslashes literally, which is ideal for regex patterns.

## Application Order

Patches are applied in numerical order:

1. `01-fix-locale-python313-compat.patch` - Applied first (affects early imports)
2. `02-fix-regex-escape-sequences.patch` - Applied second (accounts for line number shift from patch 1)

## Maintenance Notes

- Both patches target the same file (`bin/user/belchertown.py`)
- Patches are version-specific for Belchertown v1.3.1
- All fixes are backward compatible with Python 3.8+

## Testing

To verify patches apply correctly:

```bash
# Test individual patches (dry run)
patch -p0 --dry-run < 01-fix-locale-python313-compat.patch
patch -p0 --dry-run < 02-fix-regex-escape-sequences.patch

# Test in sequence (as applied by patch script)
cp bin/user/belchertown.py bin/user/belchertown.py.orig
patch -p0 < 01-fix-locale-python313-compat.patch
patch -p0 < 02-fix-regex-escape-sequences.patch
```

## Contributing

When adding new patches:

1. Use descriptive filenames: `XX-fix-description.patch`
2. Add comprehensive header comments explaining the issue
3. Update this README.md
4. Test patch application order
5. Consider line number impacts on subsequent patches