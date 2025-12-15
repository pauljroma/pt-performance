# PGVector Metagraph Registration

## Overview

The `metagraph_pgvector_registration.py` script provides **dynamic, automatic registration** of PGVector embedding tables into the Neo4j metagraph.

**Key Innovation:** No hardcoded table lists. Tables are discovered directly from PGVector's `information_schema` and registered with intelligent metadata inference.

## Architecture

### Data Flow

```
PGVector Database
    ↓
information_schema.tables (discovery)
    ↓
Extract metadata (dimensions, row_count, entity_type)
    ↓
Neo4j Metagraph
    ↓
EmbeddingSpace nodes with full metadata
```

### Pattern Source

This implementation follows the proven discovery pattern from `unified_query_layer.py` (method `_discover_pgvector_tables()`):

- **Dynamic discovery** via information_schema, not hardcoded lists
- **Inference** of entity_type, quality_tier, priority from table naming patterns
- **Integration** with Neo4j metagraph for intelligent query routing

## Usage

### Run the Script

```bash
cd /Users/expo/Code/expo/clients/quiver

python3 quiver_platform/zones/z07_data_access/metagraph_pgvector_registration.py
```

### Output

The script provides:

1. **Discovery Phase**: Finds all embedding tables in PGVector
2. **Registration Phase**: Creates/updates EmbeddingSpace nodes in Neo4j
3. **Verification Phase**: Validates registration with detailed statistics
4. **Summary Report**: Shows breakdown by entity_type, quality_tier, priority

Example output:

```
================================================================================
PGVector Metagraph Registration Summary
================================================================================

Discovery Statistics:
  Discovered:     61
  Created:        37
  Updated:        24
  Skipped (empty):32
  Errors:         0

Metagraph Verification:
  Total EmbeddingSpace nodes: 78
  Entity types registered:    11
  Average dimension:          21.7D
  Max row count:              478,770

Breakdown by Entity Type:
  gene                 :  29 spaces,  25.0D avg, 377,691 total rows
  adverse_event        :   5 spaces,  17.6D avg, 1,071,812 total rows
  drug                 :   5 spaces,  23.8D avg, 816,885 total rows
  ...

Breakdown by Quality Tier:
  Tier A: 19 spaces
  Tier B: 59 spaces

✅ PGVector embedding tables registered to metagraph!
```

## EmbeddingSpace Node Structure

### Node Properties

```cypher
CREATE (e:EmbeddingSpace {
    name: "Human Readable Table Name",
    table_name: "actual_table_name",
    dimension: 32,                      // vector dimensionality
    row_count: 292768,                  // records in table
    entity_type: "drug",                // inferred from table name
    quality_tier: "A",                  // A=v5, B=v4, C=v3+
    priority: "primary",                // primary/fallback/fusion/enhancement
    pgvector_status: "loaded",          // always 'loaded' after registration
    embedding_version: "v5_0",          // major version
    last_synced: datetime(),            // last registration timestamp
    created_at: datetime()              // initial creation time
})
```

## Discovery Logic

### Table Discovery

The script queries PGVector for tables matching:
- Contains 'embedding' column
- Table names match patterns: `*modex*`, `*ens*`, `*lincs*`, `*ep*`, `*embedding*`, etc.

```sql
SELECT table_name, has_embedding_column
FROM information_schema.tables
WHERE table_name LIKE '%modex%'
   OR table_name LIKE '%ens%'
   OR table_name LIKE '%lincs%'
   ... (20+ patterns)
```

### Metadata Extraction

For each discovered table:

1. **Row Count**: `SELECT COUNT(*) FROM table_name`
2. **Dimensions**: `SELECT vector_dims(embedding) FROM table_name LIMIT 1`
3. **Entity Type**: Inferred from naming patterns (see below)
4. **Quality Tier**: Based on version in name (v5→A, v4→B, v3→C)
5. **Priority**: MODEX>ENS>LINCS>other

### Inference Rules

#### Entity Type (from table name)

```python
'gene'           if 'gene' in name
'drug'           if 'drug' in name
'protein'        if 'protein' in name
'pathway'        if 'pathway' or 'mop' in name
'disease'        if 'disease' or 'dgp' in name
'synapse'        if 'synapse' or 'syn' in name
'adverse_event'  if 'adverse' or 'adr' in name
'cell_type'      if 'cell_type' or 'cto' in name
'dipole'         if 'dipole' in name
'quadpole'       if 'quadpole' in name
'tripole'        if 'tripole' in name
```

#### Quality Tier

```python
'A'  if 'v5' in name        # Latest version
'B'  if 'v4' in name        # Previous version
'C'  if 'v3' in name        # Older versions
'B'  default                # Unknown versions
```

#### Priority

```python
'primary'       if 'modex' in name      # Preferred for bridging
'fallback'      if 'ens' in name        # Gene standard
'fusion'        if 'lincs' in name      # Drug standard
'enhancement'   otherwise               # Supplementary
```

## Query Examples

### Find All Drug Embedding Spaces

```cypher
MATCH (e:EmbeddingSpace)
WHERE e.entity_type = 'drug'
RETURN e.table_name, e.dimension, e.row_count, e.priority
ORDER BY e.dimension DESC
```

Result:
```
table_name                  dimension  row_count  priority
lincs_drug_32d_v5_0         32         292,768    fusion
ep_drug_39d_v5_0            39         13,275     enhancement
modex_drug_lincs_16d_v5_0   16         292,768    primary
modex_drug_ep_16d_v5_0      16         2,828      primary
```

### Find Primary (MODEX) Spaces

```cypher
MATCH (e:EmbeddingSpace)
WHERE e.priority = 'primary'
  AND e.entity_type IN ['gene', 'drug', 'protein']
RETURN e.entity_type, COUNT(e) as count, AVG(e.dimension) as avg_dims
GROUP BY e.entity_type
```

### Find Highest Quality Tier A Embeddings

```cypher
MATCH (e:EmbeddingSpace)
WHERE e.quality_tier = 'A'
  AND e.row_count > 10000
RETURN e.name, e.dimension, e.row_count
ORDER BY e.row_count DESC
LIMIT 20
```

## Integration with unified_query_layer.py

The metagraph registration enables intelligent embedding space selection:

```python
# unified_query_layer.py uses metagraph to discover capabilities
embedding_spaces = self._discover_pgvector_tables()

# Spaces are scored for selection
best_space = self._select_embedding_space(
    capabilities,
    query_params,
    intent
)

# Selection factors:
# - Query intent match
# - Historical success rate (learned)
# - Entity type compatibility
# - Priority (MODEX > ENS > LINCS)
# - Data quality tier (A > B > C)
```

## Statistics

### Current Registration (2025-12-01)

- **Total Tables**: 78 EmbeddingSpace nodes
- **Newly Discovered**: 61 tables (with pgvector_status='loaded')
- **Entity Types**: 12 distinct types
- **Quality Distribution**: 19 A-tier, 59 B-tier
- **Priority Distribution**: 43 primary, 8 fallback, 7 enhancement, 3 fusion

### Coverage by Entity Type

| Type | Count | Avg Dims | Total Rows |
|------|-------|----------|-----------|
| gene | 29 | 25.0D | 377,691 |
| adverse_event | 5 | 17.6D | 1,071,812 |
| drug | 5 | 23.8D | 816,885 |
| synapse | 5 | 14.6D | 19,834 |
| pathway | 2 | 14.5D | 218,074 |
| disease | 1 | 12.0D | 3,245 |

## Automation

To run registration periodically:

### Cron Job (Linux/Mac)

```bash
# Register PGVector tables every day at 2 AM
0 2 * * * cd /Users/expo/Code/expo/clients/quiver && python3 quiver_platform/zones/z07_data_access/metagraph_pgvector_registration.py >> /var/log/pgvector_registration.log 2>&1
```

### N8N Workflow

Can be integrated into N8N workflows:

1. Trigger: Daily schedule
2. Action: Run metagraph_pgvector_registration.py
3. Monitor: Log success/failure stats
4. Alert: On error or if no tables discovered

## Troubleshooting

### No Tables Discovered

**Issue**: Script finds 0 embedding tables

**Solutions**:
1. Check PGVector connection: `psql -h localhost -U postgres -d sapphire_database -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE '%embedding%'"`
2. Verify embedding column exists: `SELECT column_name FROM information_schema.columns WHERE table_name = 'your_table'`
3. Check table naming patterns match discovery rules

### Connection Errors

**Issue**: Cannot connect to Neo4j or PGVector

**Solutions**:
1. Verify Neo4j running: `curl http://localhost:7687/`
2. Verify PGVector running: `psql -h localhost -U postgres -d sapphire_database -c "SELECT version()"`
3. Update connection parameters in script

### Slow Registration

**Issue**: Script takes >1 minute

**Solutions**:
1. Check PGVector load: `SELECT COUNT(*) FROM information_schema.tables`
2. Verify vector_dims() performance on largest table
3. Consider batch registration for very large schemas

## Development Notes

### Adding New Inference Rules

To handle new table naming patterns, update these methods:

1. **_infer_entity_type()**: Add pattern for new entity type
2. **_infer_quality_tier()**: Handle new version schemes
3. **_infer_priority()**: Adjust priority logic

Example:

```python
def _infer_entity_type(self, table_name: str) -> str:
    """Infer entity type from table naming pattern"""
    table_lower = table_name.lower()

    if 'my_new_entity' in table_lower:  # Add new pattern
        return 'my_new_entity'
    elif 'gene' in table_lower:
        return 'gene'
    # ... rest of patterns
```

### Performance Optimization

For large schemas (1000+ tables):

1. **Batch Mode**: Register in chunks of 100
2. **Parallel Query**: Use pgvector connection pool
3. **Async Neo4j**: Convert to async_driver for faster writes

## References

- **Source**: `/Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z07_data_access/metagraph_pgvector_registration.py`
- **Pattern Source**: `unified_query_layer.py` (method `_discover_pgvector_tables()`)
- **Metagraph Design**: Neo4j EmbeddingSpace node structure
- **PGVector Docs**: https://github.com/pgvector/pgvector

## Version History

### v2.0 (2025-12-01)
- Dynamic discovery via information_schema (no hardcoded lists)
- Intelligent metadata inference
- Integration with unified_query_layer pattern
- Comprehensive statistics and verification
- Support for 20+ entity types

### v1.0 (2025-11-01)
- Initial static table registration
- Hardcoded table lists
- Basic metadata only

## Author

Quiver Platform - Metagraph Integration Team
Zone: z07_data_access
Date: 2025-12-01
