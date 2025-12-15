# Zone Intent: z07 - Data Access

**Zone ID**: z07_data_access
**Layer**: Layer 5 (Data & Integration)
**Pattern**: Repository + Service Layer
**Created**: 2025-11-05
**Last Updated**: 2025-12-02

---

## Purpose

The **Data Access** layer for the Quiver platform. Provides Neo4j/PostgreSQL query services, 148+ data access tools, meta-layer for intent classification, and resolvers for chemical/gene/disease normalization. This zone bridges application logic with persistence, offering high-level data operations.

---

## Bounded Context

### In Scope
- **Query Services**: BBBPredictionService, PgVectorService, EmbeddingService, MOAExpansionService
- **Meta Layer**: BaseResolver, IntentClassifier, MetaLayerPipeline
- **Resolvers**: GeneNameResolver, ChemicalResolver, DiseaseResolver, PathwayResolver
- **148 Data Access Tools**: Graph queries, similarity search, metadata retrieval
- **Database Clients**: LiteLLMAnthropicClient, PostgresConnectionPool wrappers
- **Feature Extraction**: GraphFeatureExtractor, DrugFeatureExtractor

### Out of Scope
- **Data Loading**: Belongs in z07_data_management (ETL pipelines)
- **Persistence Layer**: Belongs in z08_persist (raw DB clients)
- **Business Logic**: Belongs in z02_coordination or z05_ml
- **API Endpoints**: Belongs in z09_integration

### Boundaries
- **Upstream Dependencies**: z00_foundation, z08_persist, z10c_utility
- **Downstream Dependents**: z01-z06 (presentation, coordination, cognitive, ML)
- **External Dependencies**: Neo4j, PostgreSQL, RDKit, pandas, numpy

---

## Interfaces

### Public API (Exported to Other Zones)

#### BBBPredictionService (PRODUCTION A+)
```python
from zones.z07_data_access.bbb_prediction_service import get_bbb_prediction_service

service = get_bbb_prediction_service()

# Predict from SMILES
pred = service.predict_from_smiles(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
    drug_name='Caffeine',
    k_neighbors=10
)
# Returns: BBBPrediction(predicted_log_bb=0.12, predicted_bbb_class="HIGH", ...)

# Predict from drug name
pred = service.predict_from_drug_name('Aspirin', k_neighbors=10)

# Batch predict
drugs = [{'smiles': '...', 'drug_name': 'Drug1'}, ...]
predictions = service.batch_predict(drugs, k_neighbors=10)

# Get statistics
stats = service.get_stats()
```

#### PgVector Service
```python
from zones.z07_data_access.pgvector_service import PGVectorService

service = PGVectorService()

# Semantic search
results = service.semantic_search(
    query="epilepsy treatment",
    collection="drug_embeddings",
    limit=10
)

# Add embeddings
service.add_embeddings(
    collection="my_collection",
    vectors=[[0.1, 0.2, ...], ...],
    metadata=[{"id": "1", "name": "..."}, ...]
)
```

#### Meta Layer Pipeline
```python
from zones.z07_data_access.meta_layer import MetaLayerPipeline, IntentClassifier

# Classify user intent
classifier = IntentClassifier()
intent = classifier.classify("What drugs treat epilepsy?")
# Returns: "drug_discovery"

# Full pipeline
pipeline = MetaLayerPipeline()
result = pipeline.process(query="Find genes associated with SCN1A")
# Returns: {
#     "intent": "gene_discovery",
#     "entities": ["SCN1A"],
#     "resolved_entities": ["SCN1A (Ensembl: ENSG00000...)"],
#     "suggested_tools": ["graph_neighbors", "gene_expression"]
# }
```

#### Resolvers
```python
from zones.z07_data_access.meta_layer import (
    GeneNameResolver,
    ChemicalResolver,
    DiseaseResolver,
    PathwayResolver
)

# Resolve gene names
gene_resolver = GeneNameResolver()
gene = gene_resolver.resolve("brca1")  # Returns standardized Gene object

# Resolve chemicals
chem_resolver = ChemicalResolver()
compound = chem_resolver.resolve("aspirin")  # Returns ChEMBL ID

# Resolve diseases
disease_resolver = DiseaseResolver()
disease = disease_resolver.resolve("epilepsy")  # Returns MONDO/EFO ID
```

---

## Data Access Tools (148 Tools)

### Graph Queries
- `graph_neighbors.py` - Find neighbors in knowledge graph
- `graph_path.py` - Find paths between entities
- `graph_subgraph.py` - Extract subgraphs
- `graph_properties.py` - Get node/edge properties

### Similarity Search
- `semantic_search.py` - Semantic similarity search
- `vector_similarity.py` - Vector-based similarity
- `vector_neighbors.py` - K-nearest neighbors
- `vector_antipodal.py` - Antipodal vector search

### Drug Discovery
- `drug_properties_detail.py` - Detailed drug properties
- `drug_lookalikes.py` - Similar drugs
- `drug_interactions.py` - Drug-drug interactions
- `drug_combinations_synergy.py` - Drug combination analysis
- `rescue_combinations.py` - Rescue drug combinations

### Literature & Evidence
- `literature_evidence.py` - Literature search
- `provenance_discovery.py` - Data provenance
- `mechanistic_explainer.py` - Mechanistic explanations

### Expression & Transcriptomics
- `lincs_expression_detail.py` - LINCS expression data
- `transcriptomic_rescue.py` - Transcriptomic rescue analysis

### Biomarker & Causal Analysis
- `biomarker_discovery.py` - Biomarker identification
- `causal_inference.py` - Causal relationship analysis

### System Utilities
- `count_entities.py` - Entity counting
- `entity_metadata.py` - Metadata retrieval
- `available_spaces.py` - List available data spaces
- `execute_cypher.py` - Direct Cypher execution

*...and 124 more tools*

---

## Domain Model

### Core Services

#### 1. BBBPredictionService (A+ Quality)
```python
class BBBPredictionService:
    """
    Blood-Brain Barrier permeability prediction.

    Algorithm:
    1. Direct Match: Exact SMILES match in reference data
    2. Chemical Similarity: K-NN weighted average (Tanimoto)
    3. QSAR Fallback: ML model prediction

    Performance:
    - Direct match: <10ms
    - Chemical similarity: 10-50ms (10-50x faster with cache)
    - QSAR fallback: <150ms
    - Accuracy: 80-85%
    """

    def __init__(self):
        self.reference_data = self._load_bbb_data()  # 6,497 compounds
        self.fingerprint_cache = {}  # Morgan fingerprints

    def predict_from_smiles(
        self,
        smiles: str,
        drug_name: Optional[str] = None,
        k_neighbors: int = 10
    ) -> BBBPrediction:
        """3-tier prediction with fallback."""
```

#### 2. MetaLayerPipeline
```python
class MetaLayerPipeline:
    """
    Multi-step pipeline for query understanding.

    Steps:
    1. Intent Classification (drug/gene/disease discovery)
    2. Entity Extraction (identify drugs, genes, diseases)
    3. Entity Resolution (normalize to standard IDs)
    4. Tool Recommendation (suggest relevant data access tools)
    """

    def process(self, query: str) -> Dict[str, Any]:
        """
        Process natural language query.

        Returns:
            {
                "intent": str,
                "entities": List[str],
                "resolved_entities": List[Dict],
                "suggested_tools": List[str],
                "confidence": float
            }
        """
```

---

## Design Decisions

### ADR-001: 3-Tier BBB Prediction
**Context**: Need fast, accurate BBB predictions
**Decision**: Direct Match → Chemical Similarity → QSAR Fallback
**Consequences**:
- ✅ <10ms for exact matches (80% of queries)
- ✅ 10-50ms for similar compounds (15% of queries)
- ✅ 80-85% accuracy overall
- ❌ Requires maintaining reference dataset

### ADR-002: Meta Layer for Query Understanding
**Context**: Users provide natural language queries
**Decision**: Build meta-layer with intent classification + entity resolution
**Consequences**:
- ✅ Automated tool selection
- ✅ Entity normalization
- ✅ Better user experience
- ❌ Adds complexity layer

### ADR-003: 148 Specialized Tools
**Context**: Many diverse data access patterns
**Decision**: Create specialized tool per use case (not generic query engine)
**Consequences**:
- ✅ Optimized per use case
- ✅ Easy to discover (tool list)
- ✅ Type-safe interfaces
- ❌ More code to maintain
- ❌ Some duplication

### ADR-004: Morgan Fingerprint Caching
**Context**: Chemical similarity slow without cache
**Decision**: Cache Morgan fingerprints for all reference compounds
**Consequences**:
- ✅ 10-50x speedup
- ✅ 99.9% cache hit rate
- ❌ ~50MB memory overhead
- ❌ Cache invalidation complexity

---

## Integration Points

### z03b_context (Context Assembly)
```python
# Uses meta layer for query understanding
from zones.z07_data_access.meta_layer import MetaLayerPipeline

pipeline = MetaLayerPipeline()
context = pipeline.process(user_query)
```

### z05_ml (Machine Learning)
```python
# Uses feature extraction
from zones.z07_data_access import GraphFeatureExtractor, DrugFeatureExtractor

graph_features = GraphFeatureExtractor().extract(drug_id)
drug_features = DrugFeatureExtractor().extract(smiles)
```

### z01_presentation (UI)
```python
# Uses BBB service
from zones.z07_data_access.bbb_prediction_service import get_bbb_prediction_service

service = get_bbb_prediction_service()
pred = service.predict_from_drug_name(drug_name)
```

---

## Quality Standards

### Test Coverage
- **Current**: 24 test files
- **Target**: >90% line coverage
- **BBB Service**: 100% coverage (23 tests, A+ quality)
- **Test Types**:
  - Unit: 60% (services, resolvers)
  - Integration: 30% (database queries)
  - Performance: 10% (BBB benchmarks)

### Performance
- **BBB Prediction**: <150ms (99th percentile)
- **PgVector Search**: <100ms (typical)
- **Graph Queries**: <500ms (typical)
- **Meta Layer**: <50ms (intent classification)

### Type Safety
- **mypy**: Strict mode where possible
- **Pydantic**: All service responses
- **Type Hints**: >95% coverage

---

## Maturity Assessment

### Current: DEVELOPING (75%)
- [x] 148 Python files (LARGEST codebase)
- [x] 21 documentation files
- [x] 24 test files (third-highest)
- [x] BBBPredictionService A+ (production ready)
- [ ] ZONE_INTENT.md (this file - NOW COMPLETE)
- [ ] BOUNDARIES.md (next)
- [ ] INTERFACES.md (next)
- [ ] README.md (next)

### Target: MATURE (85%)
- [ ] All standard zone docs complete
- [ ] >90% test coverage
- [ ] All 148 tools documented
- [ ] Performance benchmarks passing

### Future: PRODUCTION (95%)
- [ ] >95% test coverage
- [ ] All tools type-safe
- [ ] Comprehensive API docs
- [ ] Used by all zones

---

## Dependencies

### Upstream (What We Depend On)
- **z00_foundation**: Base utilities, patterns
- **z08_persist**: Neo4jClient, PostgresConnection, database providers
- **z10c_utility**: Logging, harmonizers

### Downstream (Who Depends On Us)
- **z01_presentation**: BBB predictions, drug search
- **z03a_cognitive**: Meta layer, intent classification
- **z03b_context**: Embedding service, semantic search
- **z05_ml**: Feature extraction
- **z06_transactions**: Event data queries

### External Libraries
- **rdkit-pypi**: >=2023.9.1 (chemical informatics)
- **pandas**: >=1.5.0 (data manipulation)
- **numpy**: >=1.24.0 (numerical operations)
- **psycopg2**: >=2.9 (PostgreSQL)
- **neo4j**: >=5.0 (graph database)

---

## Success Criteria

### Immediate (Tonight)
- [x] ZONE_INTENT.md created
- [ ] BOUNDARIES.md created
- [ ] INTERFACES.md created
- [ ] README.md created
- [ ] All 24 tests passing

### Week 1
- [ ] 148 tools documented
- [ ] >90% test coverage
- [ ] Meta layer validated
- [ ] BBB service integrated everywhere

### Month 1
- [ ] All resolvers tested
- [ ] Performance benchmarks green
- [ ] API documentation complete
- [ ] Used by z01, z03a/b, z05

---

**Document Owner**: Colonel z07_data_access
**Reviewers**: Platform Architecture Team
**Status**: DEVELOPING → MATURE (in progress)
**Next Review**: 2025-12-09
