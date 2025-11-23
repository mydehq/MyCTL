#!/usr/bin/awk -f

# AWK script to parse and format keybind tables into Pango markup format
# This script processes markdown tables containing keybinds and their descriptions

# Function to apply common keybind cleanup
function clean_key(k) {
    gsub(/ \+ /, "+", k)
    gsub(/^\s+|\s+$/, "", k)
    return k
}

# Function to escape HTML entities for Pango markup
function escape_html(text) {
    gsub(/&/, "\\&amp;", text)
    gsub(/</, "\\&lt;", text)
    gsub(/>/, "\\&gt;", text)
    return text
}

# Function to print a separator line (an empty row)
function print_spacer() {
    print ""
}

# Initialize variables
BEGIN {
    skip_section = 0
}

# Handle skip comment markers
/^<!-- SKIP_START -->/ {
    skip_section = 1
    next
}

/^<!-- SKIP_END -->/ {
    skip_section = 0
    next
}

# Skip everything when in skip section
skip_section == 1 {
    next
}

# Handle section headers - print spacer before new category
/^## / {
    print_spacer()
    next
}

# Skip non-data lines
/^\s*---/        { next }
/^\s*$/          { next }
/^\s*\| *:---/   { next }
/^\s*\| Keys/    { next }
/^\s*\| Keybind/ { next }

# Process table rows
/^\s*\| / {
    line = $0

    # Extract data from table row
    gsub(/^\s*\|\s*/, "", line)
    gsub(/\s*\|\s*$/, "", line)
    split(line, fields, /\|/)

    keybind_raw = fields[1]
    action = fields[2]

    # Clean up action string
    action_cleaned = action
    gsub(/\*\*/, "", action_cleaned)
    gsub(/\s{2,}/, " ", action_cleaned)
    gsub(/^\s+|\s+$/, "", action_cleaned)
    gsub(/\*+/, "", action_cleaned)

    # Skip lines with empty or invalid actions
    if (length(action_cleaned) < 5) {
        next
    }

    # Clean up keybind string
    keybind_raw_cleaned = keybind_raw
    gsub(/`|<br>|&nbsp;|\s{2,}/, " ", keybind_raw_cleaned)

    # Handle keybinds with alternatives (split by slash)
    if (keybind_raw_cleaned ~ /\//) {
        # Extract first keybind
        first_key = keybind_raw_cleaned
        sub(/\/.*/, "", first_key)
        first_key = clean_key(first_key)

        # Extract second keybind
        second_key = keybind_raw_cleaned
        sub(/[^/]*\/\s*/, "", second_key)
        second_key = clean_key(second_key)

        # Check if this is a real split or just a keybind containing slash
        if (length(first_key) > 0 && length(second_key) > 0) {
            # Process first keybind
            first_key_clean = first_key
            first_key = escape_html(first_key)
            action_cleaned = escape_html(action_cleaned)

            # Calculate padding for alignment
            padding1 = 30 - length(first_key_clean)
            spaces1 = ""
            for (i = 0; i < padding1; i++) {
                spaces1 = spaces1 " "
            }
            printf "<b>%s</b>%s %s\n", first_key, spaces1, action_cleaned

            # Process second keybind
            second_key_clean = second_key
            second_key = escape_html(second_key)

            # Calculate padding for alignment
            padding2 = 30 - length(second_key_clean)
            spaces2 = ""
            for (i = 0; i < padding2; i++) {
                spaces2 = spaces2 " "
            }
            printf "<b>%s</b>%s %s\n", second_key, spaces2, action_cleaned
        } else {
            # Treat as single keybind containing slash
            keybind = clean_key(keybind_raw_cleaned)
            keybind_clean = keybind
            keybind = escape_html(keybind)
            action_cleaned = escape_html(action_cleaned)

            # Calculate padding for alignment
            padding = 30 - length(keybind_clean)
            spaces = ""
            for (i = 0; i < padding; i++) {
                spaces = spaces " "
            }
            printf "<b>%s</b>%s %s\n", keybind, spaces, action_cleaned
        }
    } else {
        # Process standard single keybind
        keybind = clean_key(keybind_raw_cleaned)
        keybind_clean = keybind
        keybind = escape_html(keybind)
        action_cleaned = escape_html(action_cleaned)

        # Calculate padding for alignment
        padding = 30 - length(keybind_clean)
        spaces = ""
        for (i = 0; i < padding; i++) {
            spaces = spaces " "
        }
        printf "<b>%s</b>%s %s\n", keybind, spaces, action_cleaned
    }
}
