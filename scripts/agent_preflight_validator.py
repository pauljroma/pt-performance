#!/usr/bin/env python3
"""
Agent Preflight Validator

Validates agent configuration and environment before execution.
Checks for required dependencies, environment variables, and permissions.
"""

import sys
import os
import subprocess
from pathlib import Path

def validate_environment():
    """Validate required environment variables"""
    required_vars = ['EXPO_HOME', 'ANTHROPIC_API_KEY']
    missing = [v for v in required_vars if not os.getenv(v)]
    
    if missing:
        print(f"✗ Missing environment variables: {', '.join(missing)}")
        return False
    print("✓ Environment variables validated")
    return True

def validate_dependencies():
    """Check for required Python packages"""
    required_packages = ['anthropic', 'pydantic']
    missing = []
    
    for pkg in required_packages:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    
    if missing:
        print(f"✗ Missing packages: {', '.join(missing)}")
        return False
    print("✓ Dependencies validated")
    return True

def validate_permissions():
    """Check file permissions"""
    expo_home = os.getenv('EXPO_HOME', '/Users/expo/Code/expo')
    
    if not os.access(expo_home, os.W_OK):
        print(f"✗ No write permission to {expo_home}")
        return False
    print("✓ Permissions validated")
    return True

def main():
    print("=" * 60)
    print("AGENT PREFLIGHT VALIDATION")
    print("=" * 60)
    
    checks = [
        ("Environment", validate_environment),
        ("Dependencies", validate_dependencies),
        ("Permissions", validate_permissions),
    ]
    
    results = []
    for name, check in checks:
        print(f"\n{name}:")
        results.append(check())
    
    print("\n" + "=" * 60)
    if all(results):
        print("✓ ALL PREFLIGHT CHECKS PASSED")
        return 0
    else:
        print("✗ PREFLIGHT CHECKS FAILED")
        return 1

if __name__ == "__main__":
    sys.exit(main())
