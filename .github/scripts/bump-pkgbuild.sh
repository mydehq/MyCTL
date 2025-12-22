#!/bin/bash

set -e

NEW_VERSION="$1"

# Check if version was passed
if [ -z "$NEW_VERSION" ]; then
    echo "Error: No version argument provided."
    exit 1
fi

echo "📦 Bumping PKGBUILD to version ${NEW_VERSION}..."

# 1. Update pkgver
sed -i "s/^ *pkgver=.*/pkgver=${NEW_VERSION}/" PKGBUILD

# 2. Reset pkgrel to 1
sed -i "s/^ *pkgrel=.*/pkgrel=1/" PKGBUILD

# 4. Stage the file for the release commit
git add PKGBUILD

echo "✅ PKGBUILD updated and staged."
