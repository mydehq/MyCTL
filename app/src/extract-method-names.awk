#!/usr/bin/awk -f
#
# extract-method-names.awk - Extract function names from shell scripts
#
# Usage:
#   awk -f extract-method-names.awk script.sh
#
# This script identifies shell function definitions and outputs just the function names.
# It handles various function definition styles and avoids false positives from comments.
#
# Supported function definition patterns (all bash/POSIX supported patterns):
#
#   - function_name() {
#   - function_name(){
#   - function_name()
#
#   - function.name() {
#   - function.name(){
#   - function.name()
#
#   - functionName() {
#   - functionName(){
#   - functionName()
#
#   - _function.name() {
#   - _function.name(){
#   - _function.name()
#
#   - _function_name() {
#   - _function_name(){
#   - _function_name()
#
#   - _functionName() {
#   - _functionName(){
#   - _functionName()
#
#   - function function_name
#   - function functionName
#   - function function.name
#   - function function_name {
#   - function functionName {
#   - function _function_name
#   - function _functionName
#   - function _function.name
#
#   - one_liner_posix(){ echo "✅ Style 4a: One-liner POSIX style"; }
#   - one_liner_keyword function(){ echo "✅ Style 4b: One-liner keyword style"; }

# Avoids matching:
#   - Comments containing function-like text
#   - Usage examples in comments
#   - Function calls
#   - Variable assignments that look like functions

BEGIN {
    # Initialize state variables
    pending_function = ""
    brace_level = 0
    pending_brace_level = 0
}

# Skip comment lines and empty lines
/^[ \t]*#/ { next }
/^[ \t]*$/ { next }

# Check for pending function from previous line
pending_function != "" {
    if (/^[ \t]*\{/) {
        # Found opening brace on next line, print the pending function only if top-level
        if (pending_brace_level == 0) {
            print pending_function
        }
        brace_level++
    }
    # Reset pending function regardless
    pending_function = ""
    pending_brace_level = 0
}

# Match function definitions with 'function' keyword and opening brace
/^[ \t]*function[ \t]+[a-zA-Z_][a-zA-Z0-9_.-]*[ \t]*\{/ {
    # Only extract top-level functions
    if (brace_level == 0) {
        # Remove leading whitespace and 'function' keyword
        gsub(/^[ \t]*function[ \t]+/, "")
        # Remove trailing whitespace and opening brace and anything after it
        gsub(/[ \t]*\{.*$/, "")
        # Print the function name
        print
    }
    brace_level++
    next
}

# Match function definitions with 'function' keyword without opening brace
/^[ \t]*function[ \t]+[a-zA-Z_][a-zA-Z0-9_.-]*[ \t]*$/ {
    # Remove leading whitespace and 'function' keyword
    gsub(/^[ \t]*function[ \t]+/, "")
    # Remove trailing whitespace
    gsub(/[ \t]*$/, "")
    # Store for next line check
    pending_function = $0
    pending_brace_level = brace_level
    next
}

# Match function definitions with parentheses and opening brace on same line
/^[ \t]*[a-zA-Z_][a-zA-Z0-9_.-]*\(\)[ \t]*\{/ {
    # Only extract top-level functions
    if (brace_level == 0) {
        # Remove leading whitespace
        gsub(/^[ \t]*/, "")
        # Extract function name by removing everything from () onwards
        sub(/\(\).*/, "")
        # Print the function name
        print
    }
    brace_level++
    next
}

# Match function definitions with parentheses but no opening brace (multi-line)
/^[ \t]*[a-zA-Z_][a-zA-Z0-9_.-]*\(\)[ \t]*$/ {
    # Remove leading whitespace
    gsub(/^[ \t]*/, "")
    # Remove parentheses and trailing whitespace
    sub(/\(\)[ \t]*$/, "")
    # Store for next line check
    pending_function = $0
    pending_brace_level = brace_level
    next
}

# Match one-liner function definitions with keyword
/^[ \t]*function[ \t]+[a-zA-Z_][a-zA-Z0-9_.-]*[ \t]*\{.*\}/ {
    # Only extract top-level functions
    if (brace_level == 0) {
        # Remove leading whitespace and 'function' keyword
        gsub(/^[ \t]*function[ \t]+/, "")
        # Remove everything from opening brace onwards
        gsub(/[ \t]*\{.*$/, "")
        # Print the function name
        print
    }
    next
}

# Match one-liner function definitions with parentheses
/^[ \t]*[a-zA-Z_][a-zA-Z0-9_.-]*\(\)[ \t]*\{.*\}/ {
    # Only extract top-level functions
    if (brace_level == 0) {
        # Remove leading whitespace
        gsub(/^[ \t]*/, "")
        # Extract function name by removing everything from () onwards
        sub(/\(\).*/, "")
        # Print the function name
        print
    }
    next
}

# Track opening and closing braces to maintain nesting level
/\{/ {
    # Count opening braces on this line
    gsub(/[^{]/, "", $0)
    brace_level += length($0)
}

/\}/ {
    # Count closing braces on this line
    gsub(/[^}]/, "", $0)
    brace_level -= length($0)
    if (brace_level < 0) brace_level = 0
}

END {
    # Handle case where file ends with a function declaration without brace
    if (pending_function != "") {
        print pending_function
    }
}
