# Harmonization Automation - Usage Guide

## Overview

The `apply_harmonization.py` script automates the application of identifier harmonization to all 27 Sapphire tools.

**Created:** 2025-11-29
**Stream:** 1.1 (Foundation & Infrastructure)

---

## Quick Start

### 1. Dry Run (Recommended First)

Test on all tools without making changes:

```bash
cd /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access
python3 apply_harmonization.py --dry-run
```

Test on a single tool:

```bash
python3 apply_harmonization.py --dry-run --tool graph_neighbors
```

### 2. Apply Changes

Apply harmonization to all remaining tools:

```bash
python3 apply_harmonization.py
```

Apply to specific tool:

```bash
python3 apply_harmonization.py --tool drug_interactions
```

---

## What the Script Does

### Automatic Changes

1. **Adds Harmonization Imports**
   ```python
   # Import harmonization utilities (Stream 1: Foundation)
   try:
       from tool_utils import harmonize_gene_id, validate_input, normalize_gene_symbol
       HARMONIZATION_AVAILABLE = True
   except ImportError:
       HARMONIZATION_AVAILABLE = False
   ```

2. **Updates Tool Descriptions**
   - Changes parameter descriptions to mention multiple ID formats
   - Gene tools: "HGNC symbol (TP53), Entrez ID (7157), UniProt ID (P04637)"
   - Drug tools: "Drug name, ChEMBL ID (CHEMBL1234), RxNorm ID, LINCS ID"

3. **Inserts Harmonization Logic**
   - Detects tool type (gene/drug/dual)
   - Adds appropriate harmonization code after parameter extraction
   - Creates harmonized variables (gene_normalized, drug_normalized)

4. **Updates Return Statements**
   - Converts simple `return {...}` to `result_dict = {...}`
   - Adds harmonization note to response

### Automatic Backups

- Creates `.py.bak` file for each modified tool
- Original file preserved before any changes
- Can restore with: `cp tool_name.py.bak tool_name.py`

### Generated Report

After running, creates a JSON report:
- `harmonization_report_YYYYMMDD_HHMMSS.json`
- Lists successful/failed/skipped tools
- Includes error details for manual review

---

## Tools Processed

### Gene Tools (7)
- `graph_neighbors` - Graph neighbor queries
- `graph_path` - Shortest path finding
- `graph_subgraph` - Subgraph extraction
- `transcriptomic_rescue` - Transcriptomic analysis
- `provenance_discovery` - Data lineage
- `entity_metadata` - Entity details
- `lincs_expression_detail` - Expression data (gene part)

### Drug Tools (7)
- `drug_interactions` - Drug-drug interactions
- `drug_lookalikes` - Similar drugs
- `drug_combinations_synergy` - Synergy predictions
- `rescue_combinations` - Rescue drug combos
- `drug_properties_detail` - ChEMBL properties
- `vector_similarity` - Drug similarity
- `semantic_search` - Semantic queries

### Dual Tools (1)
- `lincs_expression_detail` - Accepts both genes and drugs

### Already Completed (2)
- `vector_antipodal` ✅
- `vector_neighbors` ✅

---

## Manual Review Needed

Some tools may require manual adjustments:

### 1. Variable Replacement

The script adds `gene_normalized` or `drug_normalized` but may not replace all usages. Check:

```python
# BEFORE
query = f"MATCH (g:Gene {{symbol: '{gene}'}}) ..."

# AFTER (manual fix)
query = f"MATCH (g:Gene {{symbol: '{gene_normalized}'}}) ..."
```

### 2. Complex Parameter Patterns

Tools with non-standard parameter extraction may need manual logic insertion:

```python
# If script says: "Could not find gene parameter extraction"
# Manually add harmonization logic after parameter validation
```

### 3. Return Statement Variations

Complex return logic may need manual harmonization note addition:

```python
# Find all return statements with success=True
# Add harmonization note manually if script missed it
```

---

## Verification Steps

After running the script:

### 1. Check Generated Report

```bash
cat harmonization_report_*.json | python3 -m json.tool
```

Look for:
- All tools in "successful" list
- No critical errors
- Warnings about manual review

### 2. Test Updated Tools

```bash
cd /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z10c_utility/sapphire/tests
python3 -m pytest test_sapphire_v3_comprehensive_24_tools.py -v
```

Expected: Same or better pass rate (currently 95.8%)

### 3. Spot Check Files

Review a few updated tools manually:

```bash
# Compare before/after
diff tools/graph_neighbors.py.bak tools/graph_neighbors.py

# Check for harmonization imports
grep -l "HARMONIZATION_AVAILABLE" tools/*.py

# Check for harmonization logic
grep -l "harmonize_gene_id\|harmonize_drug_id" tools/*.py
```

---

## Troubleshooting

### Issue: Import Error

**Error:** `ModuleNotFoundError: No module named 'tool_utils'`

**Fix:** Ensure `tool_utils.py` exists in the same directory:

```bash
ls -la /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/tool_utils.py
```

### Issue: Script Can't Find Parameters

**Warning:** "Could not find gene parameter extraction"

**Action Required:** Manual insertion of harmonization logic

1. Open the tool file
2. Find parameter extraction: `gene = tool_input.get("gene", "")`
3. Insert harmonization block after it
4. Use vector_antipodal.py or vector_neighbors.py as reference

### Issue: Tool Already Harmonized

**Message:** "Tool already has harmonization imports - skipping"

**Resolution:** No action needed - tool was previously updated

### Issue: Backup Files Accumulate

Too many `.bak` files in tools directory.

**Cleanup:**

```bash
cd tools/
# Review backups
ls -la *.bak

# Remove old backups (after verifying changes work)
rm *.bak
```

---

## Rollback Procedure

If changes cause issues:

### Rollback Single Tool

```bash
cd /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/tools
cp graph_neighbors.py.bak graph_neighbors.py
```

### Rollback All Tools

```bash
cd /Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/tools

# Restore all backups
for file in *.bak; do
    original="${file%.bak}"
    cp "$file" "$original"
    echo "Restored $original"
done
```

---

## Advanced Usage

### Selective Application

Apply to gene tools only:

```bash
for tool in graph_neighbors graph_path graph_subgraph transcriptomic_rescue provenance_discovery entity_metadata; do
    python3 apply_harmonization.py --tool $tool
done
```

Apply to drug tools only:

```bash
for tool in drug_interactions drug_lookalikes drug_combinations_synergy rescue_combinations drug_properties_detail vector_similarity semantic_search; do
    python3 apply_harmonization.py --tool $tool
done
```

### Custom Modifications

To add custom logic, modify `apply_harmonization.py`:

```python
def get_gene_harmonization_logic(self) -> str:
    """Customize this method to change gene harmonization pattern."""
    return """
    # Your custom harmonization logic here
    """
```

---

## Success Criteria

Stream 1.1 is complete when:

- ✅ All 14 remaining tools processed by script
- ✅ Manual review completed for flagged tools
- ✅ Variables replaced (gene → gene_normalized, etc.)
- ✅ Test suite passes at ≥95.8% (maintain or improve)
- ✅ Backups created for all modified files
- ✅ Report shows 14/14 successful

---

## Next Steps

After harmonization is complete:

1. **Run Integration Tests**
   ```bash
   cd zones/z10c_utility/sapphire/tests
   python3 test_sapphire_v3_comprehensive_24_tools.py
   ```

2. **Update app_sapphire_v3.py**
   - No changes needed (tools imported dynamically)
   - Version bump optional

3. **Move to Stream 1.2**
   - Add validation framework to all 27 tools
   - Build on harmonization foundation

---

## Support Files

- `tool_utils.py` - Harmonization utilities (already created)
- `TOOL_HARMONIZATION_GUIDE.md` - Detailed patterns and examples
- `vector_antipodal.py` - Gene harmonization reference
- `vector_neighbors.py` - Dual (gene + drug) harmonization reference

---

## Contact

For issues or questions about harmonization:
1. Review TOOL_HARMONIZATION_GUIDE.md
2. Check reference implementations (vector_antipodal, vector_neighbors)
3. Review generated report for specific errors
