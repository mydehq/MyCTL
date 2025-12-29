# Bumper

This script is used to bump version numbers across multiple files in the project. It handles specific replacements defined in the `VERSION_FILES` array at the top of the script.

It can be used as a standalone CLI tool or as a **Commitizen Hook**.

## Usage

```bash
scripts/bumper.sh <new_version>
```

## Configuration

To add or modify files to be bumped, edit the `VERSION_FILES` array in `scripts/bumper.sh`.

### Syntax

The configuration uses a **Search > Replace** syntax:

```bash
"SEARCH_REGEX > REPLACEMENT"
```

- **SEARCH_REGEX**: An Extended Regex (ERE) to find the line or pattern to replace. You can use capturing groups `()` and reference them in replacement (e.g., `\1`).
- **REPLACEMENT**: The string that will replace the matched pattern.

> [!INFO]  
> Learn more about ERE [here](https://www.gnu.org/software/sed/manual/sed.html#sed-regular-expressions).

### Replacement Variables

The following variables are available for use in the **REPLACEMENT** string:

- **`{{new_version}}`**: The new version number that was passed to the script (e.g., `1.0.1`).

### Multiple Substitutions

You can define multiple substitutions for a single file by separating them with a semicolon `;`.

```bash
"SEARCH_1 > REPLACE_1 ; SEARCH_2 > REPLACE_2"
```

### How To

#### Update a simple variable
If you have `VERSION="1.0.0"` in `install.sh`:

```bash
["scripts/install.sh"]="^VERSION=.* > VERSION='{{new_version}}'"
```

#### Update multiple fields in one file
Use the `;` separator to chain rules. For example, in an Arch Linux `PKGBUILD`:

```bash
["PKGBUILD"]="^ *pkgver=.* > pkgver={{new_version}} ; ^ *pkgrel=.* > pkgrel=1"
```

#### Handle different quoting styles

Match the quoting style of the target file in your replacement string.

| Target File Content | Replacement String |
| :--- | :--- |
| `VER="1.0"` | `VER=\"{{new_version}}\"` |
| `VER='1.0'` | `VER='{{new_version}}'` |
| `VER=1.0` | `VER={{new_version}}` |

#### Update JSON files (e.g. package.json)
Match the key and value pattern. Note the escaped quotes.

```bash
["package.json"]="^  \"version\": .* >   \"version\": \"{{new_version}}\","
```

#### Update Python files (e.g. setup.py)
Preserve indentation by matching it in the replacement string.

```bash
["setup.py"]="^    version=.* >     version='{{new_version}}',"
```

#### Keep parts of the line (Capture Groups)

Use `(...)` in the Search Regex and `\1`, `\2`, etc., in the Replacement string to keep comments or other content.

**File content:**

```bash
MY_VAR="1.0.0" # Do not touch this comment
```

**Config:**

```bash
["file.sh"]="^(.*)MY_VAR=.* > \1MY_VAR=\"{{new_version}}\" # Do not touch this comment"
```
*Note: The `\1` restores the indentation captured by `(.*)` at the start of the line.*
