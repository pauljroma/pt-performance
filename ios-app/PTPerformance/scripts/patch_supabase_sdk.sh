#!/bin/bash
# Patches Supabase SDK 2.41.1 force unwrap crash on URL.host
# The SDK has `supabaseURL.host!` which crashes on iOS 26.x
# This script replaces the force unwrap with safe optional handling
# Add as a "Run Script" build phase BEFORE "Compile Sources"

SUPABASE_FILE="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/supabase-swift/Sources/Supabase/SupabaseClient.swift"

# Fallback for when BUILD_DIR isn't set (manual runs)
if [ ! -f "$SUPABASE_FILE" ]; then
    SUPABASE_FILE=$(find ~/Library/Developer/Xcode/DerivedData -path "*/PTPerformance*/SourcePackages/checkouts/supabase-swift/Sources/Supabase/SupabaseClient.swift" 2>/dev/null | head -1)
fi

if [ -z "$SUPABASE_FILE" ] || [ ! -f "$SUPABASE_FILE" ]; then
    echo "warning: Could not find Supabase SDK SupabaseClient.swift to patch"
    exit 0
fi

# Check if already patched
if grep -q 'if let host = supabaseURL.host' "$SUPABASE_FILE"; then
    echo "Supabase SDK already patched"
    exit 0
fi

# Check if the dangerous line exists
if grep -q 'supabaseURL\.host!' "$SUPABASE_FILE"; then
    echo "Patching Supabase SDK force unwrap..."
    sed -i '' 's|// default storage key uses the supabase project ref as a namespace|// default storage key uses the supabase project ref as a namespace (PATCHED: removed force unwrap)|' "$SUPABASE_FILE"
    sed -i '' 's|let defaultStorageKey = "sb-\\(supabaseURL\.host!\.split(separator: "\.")\[0\])-auth-token"|let defaultStorageKey: String\
    if let host = supabaseURL.host, let projectRef = host.split(separator: ".").first {\
      defaultStorageKey = "sb-\\(projectRef)-auth-token"\
    } else {\
      defaultStorageKey = "sb-supabase-auth-token"\
    }|' "$SUPABASE_FILE"
    echo "Supabase SDK patched successfully"
else
    echo "Supabase SDK force unwrap not found (may be a newer version)"
fi
