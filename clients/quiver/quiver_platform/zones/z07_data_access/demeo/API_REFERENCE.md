# DeMeo v2.0 - API Reference

Complete API documentation for all DeMeo modules, adapters, and clients.

---

## Table of Contents

1. [Bayesian Fusion](#bayesian-fusion)
2. [Multi-Modal Consensus](#multi-modal-consensus)
3. [V-Score Calculator](#v-score-calculator)
4. [Unified Adapter](#unified-adapter)
5. [Metagraph Client](#metagraph-client)

---

## Bayesian Fusion

**Module:** `zones.z07_data_access.demeo.bayesian_fusion`

### Data Classes

#### `ToolPrediction`

```python
@dataclass
class ToolPrediction:
    score: float          # Tool prediction score (0-1)
    confidence: float     # Tool confidence (0-1)
```

#### `BayesianFusionResult`

```python
@dataclass
class BayesianFusionResult:
    consensus_score: float                    # Final consensus (0-1)
    confidence: float                         # Overall confidence (0-1)
    confidence_interval: Tuple[float, float]  # 95% CI (lower, upper)
    tool_contributions: Dict[str, float]      # Per-tool contributions
    metadata: Dict[str, Any]                  # Additional metadata
```

### Functions

#### `fuse_tool_predictions()`

Fuse predictions from multiple tools using Bayesian evidence fusion.

```python
def fuse_tool_predictions(
    tool_results: Dict[str, ToolPrediction],
    weights: Dict[str, float] = DEFAULT_TOOL_WEIGHTS,
    prior: float = 0.50,
    n_bootstrap: int = 1000
) -> BayesianFusionResult
```

**Parameters:**
- `tool_results`: Dict mapping tool name → ToolPrediction
- `weights`: Dict mapping tool name → weight (must sum to 1.0)
- `prior`: Prior probability (0-1), default 0.50
- `n_bootstrap`: Bootstrap iterations for CI, default 1000

**Returns:** `BayesianFusionResult`

**Example:**
```python
tool_results = {
    'vector_antipodal': ToolPrediction(score=0.85, confidence=0.90),
    'bbb_permeability': ToolPrediction(score=0.91, confidence=0.88)
}
result = fuse_tool_predictions(tool_results, DEFAULT_TOOL_WEIGHTS, prior=0.50)
```

### Constants

```python
DEFAULT_TOOL_WEIGHTS = {
    'vector_antipodal': 0.15,
    'bbb_permeability': 0.18,
    'adme_tox': 0.14,
    'mechanistic_explainer': 0.17,
    'clinical_trials': 0.16,
    'drug_interactions': 0.20
}
```

---

## Multi-Modal Consensus

**Module:** `zones.z07_data_access.demeo.multimodal_consensus`

### Data Classes

#### `MultiModalConsensusResult`

```python
@dataclass
class MultiModalConsensusResult:
    consensus_vector: np.ndarray               # Weighted consensus embedding
    agreement_coefficient: float               # Cross-space agreement (0-1)
    modality_scores: Dict[str, float]          # Per-modality similarity scores
    weights_used: Dict[str, float]             # Actual weights applied
    metadata: Dict[str, Any]                   # Additional metadata
```

### Functions

#### `compute_consensus()`

Compute multi-modal consensus from MODEX/ENS/LINCS embeddings.

```python
def compute_consensus(
    vectors: Dict[str, np.ndarray],
    weights: Dict[str, float] = DEFAULT_MULTIMODAL_WEIGHTS
) -> MultiModalConsensusResult
```

**Parameters:**
- `vectors`: Dict mapping space name → embedding vector (np.ndarray)
- `weights`: Dict mapping space name → weight (must sum to 1.0)

**Returns:** `MultiModalConsensusResult`

**Example:**
```python
vectors = {
    'modex': np.array([...]),  # 16D embedding
    'ens': np.array([...]),
    'lincs': np.array([...])
}
result = compute_consensus(vectors, DEFAULT_MULTIMODAL_WEIGHTS)
print(f"Agreement: {result.agreement_coefficient:.3f}")
```

#### `calculate_agreement_coefficient()`

Calculate pairwise agreement across all embedding spaces.

```python
def calculate_agreement_coefficient(
    vectors: Dict[str, np.ndarray]
) -> float
```

**Parameters:**
- `vectors`: Dict mapping space name → embedding vector

**Returns:** Agreement coefficient (0-1), where 1 = perfect agreement

**Example:**
```python
agreement = calculate_agreement_coefficient(vectors)
print(f"Cross-space agreement: {agreement:.3f}")
```

### Constants

```python
DEFAULT_MULTIMODAL_WEIGHTS = {
    'modex': 0.50,  # Primary (50%)
    'ens': 0.30,    # Fallback (30%)
    'lincs': 0.20   # Fusion (20%)
}
```

---

## V-Score Calculator

**Module:** `zones.z07_data_access.demeo.vscore_calculator`

### Functions

#### `compute_variance_scaled_vscore()`

Compute variance-scaled v-scores using EP methodology.

```python
def compute_variance_scaled_vscore(
    wt_vec: np.ndarray,
    disease_vec: np.ndarray,
    wt_var: float,
    disease_var: float
) -> np.ndarray
```

**Parameters:**
- `wt_vec`: Wild-type embedding (np.ndarray)
- `disease_vec`: Disease embedding (np.ndarray)
- `wt_var`: Wild-type variance (float)
- `disease_var`: Disease variance (float)

**Returns:** V-score vector (np.ndarray), same shape as input

**Formula:** `v_i = (μ_disease - μ_wt) / sqrt(σ²_wt + σ²_disease)`

**Example:**
```python
wt_vec = np.array([...])       # 16D wild-type embedding
disease_vec = np.array([...])  # 16D disease embedding

vscore = compute_variance_scaled_vscore(
    wt_vec, disease_vec,
    wt_var=0.1, disease_var=0.1
)
print(f"V-score mean: {np.mean(vscore):.3f}")
```

---

## Unified Adapter

**Module:** `zones.z07_data_access.demeo.unified_adapter`

### Data Classes

#### `EmbeddingResult`

```python
@dataclass
class EmbeddingResult:
    entity_name: str            # Entity name (e.g., "SCN1A")
    entity_type: str            # "gene" or "drug"
    embedding: np.ndarray       # Embedding vector
    space: str                  # Embedding space ("modex", "ens", "lincs")
    dimension: int              # Vector dimension
    confidence: float           # Confidence score (0-1)
    source_table: str           # PGVector table name
    metadata: Dict[str, Any]    # Additional metadata
```

#### `MultiModalEmbeddingResult`

```python
@dataclass
class MultiModalEmbeddingResult:
    entity_name: str                      # Entity name
    entity_type: str                      # "gene" or "drug"
    modex: Optional[EmbeddingResult]      # MODEX embedding
    ens: Optional[EmbeddingResult]        # ENS embedding
    lincs: Optional[EmbeddingResult]      # LINCS embedding
    spaces_found: List[str]               # List of found spaces
    agreement_coefficient: Optional[float] # Agreement (if computed)
```

### Class: `DeMeoUnifiedAdapter`

Adapter for querying embeddings via Unified Query Layer.

#### `__init__()`

```python
def __init__(self, unified_query_layer):
    """
    Initialize adapter

    Args:
        unified_query_layer: UnifiedQueryLayer instance
    """
```

#### `query_gene_embedding()`

Query gene embedding from a single space.

```python
async def query_gene_embedding(
    self,
    gene: str,
    space: str = "modex",
    version: str = "v6.0"
) -> Optional[EmbeddingResult]
```

**Parameters:**
- `gene`: Gene symbol (e.g., "SCN1A")
- `space`: Embedding space ("modex", "ens", or "lincs")
- `version`: Embedding version ("v6.0" or "v5.0")

**Returns:** `EmbeddingResult` if found, `None` otherwise

**Example:**
```python
adapter = get_demeo_unified_adapter(uql)
result = await adapter.query_gene_embedding("SCN1A", space="modex")
if result:
    print(f"Embedding: {result.dimension}D from {result.source_table}")
```

#### `query_drug_embedding()`

Query drug embedding from a single space.

```python
async def query_drug_embedding(
    self,
    drug: str,
    space: str = "modex",
    version: str = "v6.0"
) -> Optional[EmbeddingResult]
```

**Parameters:**
- `drug`: Drug name or identifier
- `space`: Embedding space
- `version`: Embedding version

**Returns:** `EmbeddingResult` if found, `None` otherwise

#### `query_multimodal_embeddings()`

Query embeddings from all 3 spaces in parallel.

```python
async def query_multimodal_embeddings(
    self,
    entity: str,
    entity_type: str = "gene",
    version: str = "v6.0"
) -> MultiModalEmbeddingResult
```

**Parameters:**
- `entity`: Entity name (gene or drug)
- `entity_type`: "gene" or "drug"
- `version`: Embedding version

**Returns:** `MultiModalEmbeddingResult` with embeddings from all available spaces

**Example:**
```python
result = await adapter.query_multimodal_embeddings("SCN1A", entity_type="gene")
print(f"Found in spaces: {', '.join(result.spaces_found)}")
```

#### `batch_query_embeddings()`

Query multiple embeddings in parallel.

```python
async def batch_query_embeddings(
    self,
    entities: List[str],
    entity_type: str = "gene",
    space: str = "modex",
    version: str = "v6.0"
) -> Dict[str, Optional[EmbeddingResult]]
```

**Parameters:**
- `entities`: List of entity names
- `entity_type`: "gene" or "drug"
- `space`: Embedding space
- `version`: Embedding version

**Returns:** Dict mapping entity name → EmbeddingResult (None if not found)

**Example:**
```python
genes = ["SCN1A", "CDKL5", "KCNQ2"]
results = await adapter.batch_query_embeddings(genes, entity_type="gene")
found_count = sum(1 for r in results.values() if r is not None)
print(f"Found {found_count}/{len(genes)} embeddings")
```

### Factory Function

```python
def get_demeo_unified_adapter(unified_query_layer) -> DeMeoUnifiedAdapter
```

---

## Metagraph Client

**Module:** `zones.z07_data_access.demeo.metagraph_client`

### Data Classes

#### `LearnedRescuePattern`

```python
@dataclass
class LearnedRescuePattern:
    pattern_id: str                         # Unique pattern ID (UUID)
    gene: str                               # Gene symbol
    disease: str                            # Disease name
    drug: str                               # Drug name
    consensus_score: float                  # Consensus score (0-1)
    confidence: float                       # Confidence (0-1)
    tool_contributions: Dict[str, float]    # Per-tool contributions
    modex_vscore: float                     # MODEX v-score
    ens_vscore: float                       # ENS v-score
    lincs_vscore: float                     # LINCS v-score
    agreement_coefficient: float            # Multi-modal agreement
    cycle: int                              # Discovery cycle
    discovered_at: str                      # ISO datetime
    validated: Optional[bool]               # Validation status
    validation_date: Optional[str]          # ISO datetime
    metadata: Optional[Dict[str, Any]]      # Additional metadata
```

#### `DiseaseSignature`

```python
@dataclass
class DiseaseSignature:
    signature_id: str                      # Unique signature ID (UUID)
    gene: str                              # Gene symbol
    disease: str                           # Disease name
    v_score_summary: Dict[str, float]      # {"modex": X, "ens": Y, "lincs": Z}
    modex_weight: float                    # MODEX weight
    ens_weight: float                      # ENS weight
    lincs_weight: float                    # LINCS weight
    cycle: int                             # Discovery cycle
    created_at: str                        # ISO datetime
    metadata: Optional[Dict[str, Any]]     # Additional metadata
```

#### `MechanismCluster`

```python
@dataclass
class MechanismCluster:
    cluster_id: str                        # Unique cluster ID (UUID)
    mechanism: str                         # Mechanism name
    member_drugs: List[str]                # List of drug names
    member_count: int                      # Number of drugs
    validated_targets: List[str]           # Validated targets
    discovered_cycle: int                  # Discovery cycle
    created_at: str                        # ISO datetime
    metadata: Optional[Dict[str, Any]]     # Additional metadata
```

### Class: `DeMeoMetagraphClient`

Neo4j client for DeMeo metagraph operations.

#### `__init__()`

```python
def __init__(self, neo4j_driver):
    """
    Initialize metagraph client

    Args:
        neo4j_driver: Neo4j GraphDatabase.driver instance
    """
```

#### `store_rescue_pattern()`

Store a learned rescue pattern in the metagraph.

```python
async def store_rescue_pattern(
    self,
    pattern: LearnedRescuePattern
) -> Dict[str, Any]
```

**Parameters:**
- `pattern`: LearnedRescuePattern to store

**Returns:** Dict with `{'success': bool, 'pattern_id': str, 'score': float}`

**Example:**
```python
pattern = LearnedRescuePattern(
    pattern_id=str(uuid.uuid4()),
    gene="SCN1A",
    disease="Dravet Syndrome",
    drug="Stiripentol",
    consensus_score=0.87,
    confidence=0.92,
    tool_contributions={"vector_antipodal": 0.15, ...},
    modex_vscore=0.82,
    ens_vscore=0.79,
    lincs_vscore=0.85,
    agreement_coefficient=0.88,
    cycle=1,
    discovered_at=datetime.utcnow().isoformat() + "Z"
)
result = await client.store_rescue_pattern(pattern)
```

#### `query_rescue_patterns()`

Query cached rescue patterns from metagraph.

```python
async def query_rescue_patterns(
    self,
    gene: str,
    disease: str,
    min_confidence: float = 0.70,
    limit: int = 20
) -> List[LearnedRescuePattern]
```

**Parameters:**
- `gene`: Gene symbol
- `disease`: Disease name
- `min_confidence`: Minimum confidence threshold (0-1)
- `limit`: Maximum patterns to return

**Returns:** List of `LearnedRescuePattern`, sorted by consensus_score DESC

**Example:**
```python
patterns = await client.query_rescue_patterns("SCN1A", "Dravet Syndrome")
for pattern in patterns:
    print(f"{pattern.drug}: {pattern.consensus_score:.3f}")
```

#### `store_disease_signature()`

Store a disease signature in the metagraph.

```python
async def store_disease_signature(
    self,
    signature: DiseaseSignature
) -> Dict[str, Any]
```

#### `query_disease_signature()`

Query disease signature for a gene-disease pair.

```python
async def query_disease_signature(
    self,
    gene: str,
    disease: str
) -> Optional[DiseaseSignature]
```

#### `update_pattern_validation()`

Update validation status for a rescue pattern.

```python
async def update_pattern_validation(
    self,
    pattern_id: str,
    validated: bool,
    validation_date: Optional[str] = None
) -> Dict[str, Any]
```

**Parameters:**
- `pattern_id`: Pattern ID (UUID)
- `validated`: True if validated, False if invalidated
- `validation_date`: ISO datetime (defaults to now)

**Example:**
```python
result = await client.update_pattern_validation(
    pattern_id="abc-123",
    validated=True
)
```

#### `get_stats()`

Get statistics about stored patterns.

```python
async def get_stats(self) -> Dict[str, Any]
```

**Returns:**
```python
{
    'pattern_count': int,
    'signature_count': int,
    'cluster_count': int,
    'avg_consensus_score': float,
    'avg_confidence': float
}
```

### Factory Function

```python
def get_demeo_metagraph_client(neo4j_driver) -> DeMeoMetagraphClient
```

---

## Performance Notes

### Cython Acceleration

All core operations are Cython-accelerated with automatic fallback:

- **Bayesian Fusion**: 50x speedup (bootstrap CI)
- **Multi-Modal Consensus**: 100-1200x speedup (cosine similarity, agreement)
- **V-Score**: 30x speedup (element-wise operations)

### Caching

- **Unified Adapter**: Simple dict cache for repeated embedding queries
- **Metagraph Client**: Neo4j pattern caching for 100-1000x query speedup

### Async Support

All Unified Adapter and Metagraph Client methods are async and support parallel execution with `asyncio.gather()`.

---

## Error Handling

All functions return appropriate error indicators:

- **Embedding queries**: Return `None` if not found (no exception)
- **Metagraph operations**: Return `{'success': False, 'error': str}` on failure
- **Fusion/consensus**: Gracefully handle missing tools/modalities

---

## See Also

- **DEMEO_QUICKSTART.md** - Quick start guide
- **EXAMPLES.md** - Working code examples
- **METAGRAPH_INTEGRATION_GUIDE.md** - Neo4j setup
- **Integration Tests** - `zones/z07_data_access/demeo/tests/test_demeo_cython_integration.py`

---

**DeMeo v2.0.0-alpha1** - Complete API Reference
