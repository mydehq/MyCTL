BEGIN { FS = "=" }

# Skip empty lines or full-line comments
/^[ \t]*$/ || /^[ \t]*#/ { next }

{
    # 1. Clean the variable name (Field 1)
    # Remove leading whitespace and the '$', and trailing whitespace
    current_key = $1
    gsub(/^[ \t]*\$|[ \t]*$/, "", current_key)

    # 2. Check for EXACT match
    if (current_key == target) {
        
        # 3. Extract the value
        # We use substr to handle cases where the value itself might contain an '='
        val = substr($0, index($0, "=") + 1)

        # 4. Remove inline comments
        sub(/#.*/, "", val)

        # 5. Trim leading/trailing whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", val)

        print val
        exit
    }
}
