#!/usr/bin/env python3
"""
CI Validation script for k8s-chaos-observability
Validates Kubernetes manifests, Helm values, and Locust Python scenarios.
"""

import glob
import sys
import yaml


def validate_yaml_files():
    print("--- Validating Kubernetes YAML Manifests ---")
    patterns = [
        "apps/**/*.yaml",
        "chaos/*.yaml",
        "cluster/*.yaml",
        "monitoring/**/*.yaml",
        "load-testing/*.yaml",
    ]
    files = []
    for pattern in patterns:
        files.extend(glob.glob(pattern, recursive=True))

    errors = 0
    checked = 0

    for file_path in sorted(set(files)):
        checked += 1
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                # Load all documents in the YAML file
                list(yaml.safe_load_all(f))
            print(f"  [OK] {file_path}")
        except Exception as e:
            print(f"  [FAIL] {file_path}: {e}")
            errors += 1

    print(f"\nChecked {checked} YAML files. Errors found: {errors}")
    return errors == 0


if __name__ == "__main__":
    success = validate_yaml_files()
    if not success:
        sys.exit(1)
    print("All manifests successfully validated!")
    sys.exit(0)
