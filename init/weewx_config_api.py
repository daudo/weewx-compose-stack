#!/usr/bin/env python3
"""
WeeWX Configuration API - Generic ConfigObj operations for shell scripts
Provides a clean interface for modifying weewx.conf without complex sed/awk operations.
"""

import os
import sys
import shutil
import argparse
from pathlib import Path
from datetime import datetime
from configobj import ConfigObj


class WeewxConfigManager:
    """Generic configuration manager for WeeWX using ConfigObj"""
    
    def __init__(self, config_path="/data/weewx.conf"):
        self.config_path = Path(config_path)
        self.config = None
        
    def load(self):
        """Load weewx.conf with error handling"""
        try:
            self.config = ConfigObj(str(self.config_path), interpolation=False, encoding='utf-8')
            return True
        except Exception as e:
            print(f"Error loading config from {self.config_path}: {e}", file=sys.stderr)
            return False
    
    def save(self, backup=True):
        """Save configuration with optional backup"""
        if backup and self.config_path.exists():
            backup_path = f"{self.config_path}.py-backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
            shutil.copy2(self.config_path, backup_path)
        
        try:
            self.config.write()
            return True
        except Exception as e:
            print(f"Error saving config to {self.config_path}: {e}", file=sys.stderr)
            return False
    
    def validate(self):
        """Validate configuration syntax by attempting to parse it"""
        try:
            test_config = ConfigObj(str(self.config_path), interpolation=False, encoding='utf-8')
            return True
        except Exception as e:
            print(f"Config validation failed: {e}", file=sys.stderr)
            return False
    
    def parse_section_path(self, section_path):
        """Parse section path like '[Station]' or '[StdReport][Belchertown][Extras]'"""
        # Remove outer brackets and split on '][' 
        if section_path.startswith('[') and section_path.endswith(']'):
            section_path = section_path[1:-1]
        return section_path.split('][')
    
    def navigate_to_section(self, section_path, create_missing=False):
        """Navigate to a section, optionally creating missing sections"""
        sections = self.parse_section_path(section_path)
        current = self.config
        
        for section in sections:
            if section not in current:
                if create_missing:
                    current[section] = {}
                else:
                    return None
            current = current[section]
        
        return current
    
    # Basic Operations
    def get_value(self, section_path, key, default=None):
        """Get a configuration value"""
        section = self.navigate_to_section(section_path)
        if section is None:
            return default
        return section.get(key, default)
    
    def set_value(self, section_path, key, value):
        """Set a configuration value"""
        section = self.navigate_to_section(section_path, create_missing=True)
        section[key] = str(value)
        return True
    
    def has_section(self, section_path):
        """Check if a section exists"""
        return self.navigate_to_section(section_path) is not None
    
    def has_key(self, section_path, key):
        """Check if a key exists in a section"""
        section = self.navigate_to_section(section_path)
        return section is not None and key in section
    
    def create_section(self, section_path):
        """Create a new section"""
        self.navigate_to_section(section_path, create_missing=True)
        return True
    
    def remove_section(self, section_path):
        """Remove a section"""
        sections = self.parse_section_path(section_path)
        if len(sections) == 1:
            # Top-level section
            if sections[0] in self.config:
                del self.config[sections[0]]
                return True
        else:
            # Nested section - navigate to parent
            parent_path = '[' + ']['.join(sections[:-1]) + ']'
            parent = self.navigate_to_section(parent_path)
            if parent is not None and sections[-1] in parent:
                del parent[sections[-1]]
                return True
        return False
    
    # Bulk Operations
    def set_multiple_values(self, section_path, key_value_pairs):
        """Set multiple key=value pairs in a section"""
        section = self.navigate_to_section(section_path, create_missing=True)
        
        for pair in key_value_pairs:
            if '=' not in pair:
                raise ValueError(f"Invalid key=value pair: {pair}")
            key, value = pair.split('=', 1)
            section[key.strip()] = value.strip()
        
        return True
    
    def merge_config_from_file(self, config_file, target_section_path):
        """Merge configuration from a file into a target section"""
        try:
            # Load the source config
            source_config = ConfigObj(config_file, interpolation=False, encoding='utf-8')
            
            # Validate that source config has exactly one root section
            root_sections = list(source_config.keys())
            if len(root_sections) != 1:
                print(f"Error: Source config file {config_file} must have exactly one root section, found: {root_sections}", file=sys.stderr)
                return False
            
            # Get the source root section name
            source_root_name = root_sections[0]
            
            # Parse the target section path to get the root section name
            target_sections = self.parse_section_path(target_section_path)
            target_root_name = target_sections[0]
            
            # Validate that source root matches target root
            if source_root_name != target_root_name:
                print(f"Error: Source config root section [{source_root_name}] does not match target section root [{target_root_name}]", file=sys.stderr)
                return False
            
            # Get or create target section
            target_section = self.navigate_to_section(target_section_path, create_missing=True)
            
            # Merge the configurations (merge from the source root section)
            source_root_section = source_config[source_root_name]
            self._merge_sections(source_root_section, target_section)
            return True
            
        except Exception as e:
            print(f"Error merging config from {config_file}: {e}", file=sys.stderr)
            return False
    
    def merge_config_from_string(self, config_string, target_section_path):
        """Merge configuration from a string into a target section"""
        try:
            # Create temporary ConfigObj from string
            from io import StringIO
            source_config = ConfigObj(StringIO(config_string), interpolation=False, encoding='utf-8')
            
            # Get or create target section  
            target_section = self.navigate_to_section(target_section_path, create_missing=True)
            
            # Merge the configurations
            self._merge_sections(source_config, target_section)
            return True
            
        except Exception as e:
            print(f"Error merging config from string: {e}", file=sys.stderr)
            return False
    
    def _merge_sections(self, source, target):
        """Recursively merge source section into target section"""
        for key, value in source.items():
            if isinstance(value, dict):
                # Nested section - recurse
                if key not in target:
                    target[key] = {}
                self._merge_sections(value, target[key])
            else:
                # Simple key-value pair
                target[key] = value


def main():
    """CLI interface for shell script integration"""
    parser = argparse.ArgumentParser(
        description='WeeWX Configuration API - Generic ConfigObj operations',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s set-value "[Station]" "location" "My Weather Station"
  %(prog)s get-value "[Station]" "location"
  %(prog)s has-section "[GW1000]"
  %(prog)s create-section "[StdReport][BelchertownReport]"
  %(prog)s merge-config-from-file "/tmp/accum.conf" "[Accumulator]"
  %(prog)s set-multiple-values "[StdReport][Belchertown][Extras]" "site_title=Weather" "manifest_name=WX"
        """
    )
    
    parser.add_argument('--config', default='/data/weewx.conf',
                        help='Configuration file path (default: /data/weewx.conf)')
    parser.add_argument('--quiet', action='store_true', 
                        help='Suppress output except errors')
    parser.add_argument('--dry-run', action='store_true',
                        help='Show changes without applying them')
    
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # get-value command
    get_parser = subparsers.add_parser('get-value', help='Get a configuration value')
    get_parser.add_argument('section', help='Section path like "[Station]" or "[StdReport][Belchertown]"')
    get_parser.add_argument('key', help='Configuration key name')
    get_parser.add_argument('default', nargs='?', help='Default value if key not found')
    
    # set-value command  
    set_parser = subparsers.add_parser('set-value', help='Set a configuration value')
    set_parser.add_argument('section', help='Section path')
    set_parser.add_argument('key', help='Configuration key name')
    set_parser.add_argument('value', help='Value to set')
    
    # has-section command
    has_section_parser = subparsers.add_parser('has-section', help='Check if section exists')
    has_section_parser.add_argument('section', help='Section path')
    
    # has-key command
    has_key_parser = subparsers.add_parser('has-key', help='Check if key exists in section')
    has_key_parser.add_argument('section', help='Section path')
    has_key_parser.add_argument('key', help='Key name')
    
    # create-section command
    create_parser = subparsers.add_parser('create-section', help='Create a new section')
    create_parser.add_argument('section', help='Section path')
    
    # remove-section command
    remove_parser = subparsers.add_parser('remove-section', help='Remove a section')
    remove_parser.add_argument('section', help='Section path')
    
    # set-multiple-values command
    multi_parser = subparsers.add_parser('set-multiple-values', help='Set multiple values at once')
    multi_parser.add_argument('section', help='Section path')
    multi_parser.add_argument('pairs', nargs='+', help='Key=value pairs')
    
    # merge-config-from-file command
    merge_file_parser = subparsers.add_parser('merge-config-from-file', help='Merge config from file')
    merge_file_parser.add_argument('file', help='Configuration file to merge')
    merge_file_parser.add_argument('section', help='Target section path')
    
    # merge-config-from-stdin command
    merge_stdin_parser = subparsers.add_parser('merge-config-from-stdin', help='Merge config from stdin')
    merge_stdin_parser.add_argument('section', help='Target section path')
    
    # validate command
    validate_parser = subparsers.add_parser('validate', help='Validate configuration syntax')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    # Initialize config manager
    config_mgr = WeewxConfigManager(args.config)
    
    # Load configuration
    if not config_mgr.load():
        return 1
    
    success = True
    
    # Execute commands
    try:
        if args.command == 'get-value':
            value = config_mgr.get_value(args.section, args.key, args.default)
            if value is not None:
                print(value)
            else:
                return 1
                
        elif args.command == 'set-value':
            config_mgr.set_value(args.section, args.key, args.value)
            if not args.quiet:
                print(f"Set {args.section}[{args.key}] = {args.value}")
                
        elif args.command == 'has-section':
            exists = config_mgr.has_section(args.section)
            if not args.quiet:
                print("true" if exists else "false")
            return 0 if exists else 1
            
        elif args.command == 'has-key':
            exists = config_mgr.has_key(args.section, args.key)
            if not args.quiet:
                print("true" if exists else "false")
            return 0 if exists else 1
            
        elif args.command == 'create-section':
            config_mgr.create_section(args.section)
            if not args.quiet:
                print(f"Created section {args.section}")
                
        elif args.command == 'remove-section':
            success = config_mgr.remove_section(args.section)
            if not args.quiet:
                if success:
                    print(f"Removed section {args.section}")
                else:
                    print(f"Section {args.section} not found")
                    
        elif args.command == 'set-multiple-values':
            config_mgr.set_multiple_values(args.section, args.pairs)
            if not args.quiet:
                print(f"Set {len(args.pairs)} values in {args.section}")
                
        elif args.command == 'merge-config-from-file':
            success = config_mgr.merge_config_from_file(args.file, args.section)
            if not args.quiet and success:
                print(f"Merged {args.file} into {args.section}")
                
        elif args.command == 'merge-config-from-stdin':
            config_string = sys.stdin.read()
            success = config_mgr.merge_config_from_string(config_string, args.section)
            if not args.quiet and success:
                print(f"Merged stdin config into {args.section}")
                
        elif args.command == 'validate':
            if config_mgr.validate():
                if not args.quiet:
                    print("Configuration is valid")
                return 0
            else:
                return 1
    
    except Exception as e:
        print(f"Error executing {args.command}: {e}", file=sys.stderr)
        return 1
    
    # Save changes (except for read-only operations)
    if args.command not in ['get-value', 'has-section', 'has-key', 'validate']:
        if not args.dry_run:
            if not config_mgr.save():
                return 1
        elif not args.quiet:
            print("(dry-run mode - no changes saved)")
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())