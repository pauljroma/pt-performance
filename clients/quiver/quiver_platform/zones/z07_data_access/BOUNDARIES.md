# Zone Boundaries: z07_data_access

**Zone**: z07_data_access (Data Access Layer)
**Layer**: Layer 5 (Data & Integration)
**Total Components**: 149 Python files (LARGEST codebase)
**Last Updated**: 2025-12-02

---

## Dependency Rules

### CAN Import From (Upstream)
- ✅ `z00_foundation` - Base utilities, patterns, configuration
- ✅ `z08_persist` - Neo4jClient, PostgresConnection, database providers
- ✅ `z10c_utility` - Logging, harmonizers, validation utilities
- ✅ Python standard library
- ✅ Approved third-party libraries (rdkit, pandas, numpy, psycopg2, neo4j)

### CANNOT Import From (Higher Layers)
- ❌ `z01_presentation` - Presentation/UI layer
- ❌ `z02_coordination` - Business coordination
- ❌ `z03a/b/c` - Cognitive/AI/Context layers
- ❌ `z04a/b` - Control/rules layers
- ❌ `z05_ml` - ML layer (with EXCEPTION: z05_models/bbb_qsar_model.py for fallback)
- ❌ `z06_transactions` - Event layer
- ❌ `z09_integration` - API integration layer

### Who Can Import From Us (Downstream)
- ✅ `z01_presentation` - Uses BBB service, drug search, UI tools
- ✅ `z02_coordination` - Uses query orchestration, data pipelines
- ✅ `z03a_cognitive` - Uses meta layer, intent classification
- ✅ `z03b_context` - Uses embedding service, semantic search
- ✅ `z04a_orchestration` - Uses data access tools
- ✅ `z05_ml` - Uses feature extraction, data retrieval
- ✅ `z06_transactions` - Uses event data queries

---

## Responsibilities

### IN SCOPE

#### 1. Query Services (High-Level Data Operations)
- ✅ BBBPredictionService - Blood-brain barrier permeability prediction (A+ quality)
- ✅ PgVectorService - PostgreSQL pgvector embedding search
- ✅ EmbeddingService - File-based embedding management
- ✅ MOAExpansionService - Mechanism of action expansion
- ✅ UnifiedQueryLayer - Cross-database query orchestration

#### 2. Meta Layer (Query Understanding)
- ✅ IntentClassifier - Classify user queries (drug/gene/disease discovery)
- ✅ MetaLayerPipeline - Multi-step query processing
- ✅ BaseResolver - Abstract resolver pattern
- ✅ Entity extraction and normalization

#### 3. Resolvers (Entity Normalization)
- ✅ GeneNameResolver - Gene symbol standardization (HGNC)
- ✅ ChemicalResolver - Chemical structure resolution (ChEMBL, SMILES)
- ✅ DrugNameResolver - Drug name normalization
- ✅ DiseaseResolver - Disease identifier resolution (MONDO, EFO)
- ✅ PathwayResolver - Pathway normalization (Reactome, KEGG)

#### 4. 148 Data Access Tools
- ✅ Graph queries (neighbors, paths, subgraphs, properties)
- ✅ Similarity search (semantic, vector, k-NN, antipodal)
- ✅ Drug discovery (properties, lookalikes, interactions, combinations)
- ✅ Literature & evidence (search, provenance, mechanistic)
- ✅ Expression & transcriptomics (LINCS, rescue analysis)
- ✅ Biomarker & causal analysis
- ✅ System utilities (count, metadata, Cypher execution)

#### 5. Feature Extraction
- ✅ GraphFeatureExtractor - Extract graph-based features
- ✅ DrugFeatureExtractor - Extract chemical features
- ✅ Feature aggregation for ML pipelines

#### 6. Database Client Wrappers
- ✅ LiteLLMAnthropicClient - LLM client wrapper
- ✅ PostgresConnectionPool - Connection pooling helpers
- ✅ Neo4j query builders and utilities

### OUT OF SCOPE

#### ❌ Raw Database Clients (Belongs in z08_persist)
- Database connection management (Neo4jClient, PostgresConnection)
- Raw JDBC/driver implementations
- Connection pooling infrastructure
- Transaction management
- Note: z07 USES z08 clients, doesn't implement them

#### ❌ Data Loading & ETL (Belongs in z07_data_management)
- CSV/Parquet data ingestion
- Database schema creation
- Data migration scripts
- Bulk data loading
- ETL pipelines
- Note: z07 READS data, z07_data_management LOADS data

#### ❌ Business Logic (Belongs in z02_coordination)
- Workflow orchestration (beyond query orchestration)
- Business rules enforcement
- Transaction coordination
- Complex decision logic

#### ❌ ML Model Training (Belongs in z05_ml)
- Model training pipelines
- Hyperparameter tuning
- Model evaluation
- Feature engineering (beyond extraction)
- Note: z07 provides features, z05 trains models

#### ❌ API Endpoints (Belongs in z09_integration)
- REST route handlers
- GraphQL resolvers
- gRPC service definitions
- API authentication/authorization
- Note: z09 calls z07 services

#### ❌ Presentation Logic (Belongs in z01_presentation)
- UI components
- Frontend state management
- User interaction handling
- Display formatting

---

## Integration Patterns

### Pattern 1: BBB Prediction Service
```python
# z01_presentation uses BBB service
from zones.z07_data_access.bbb_prediction_service import get_bbb_prediction_service

service = get_bbb_prediction_service()
prediction = service.predict_from_drug_name("Fenfluramine", k_neighbors=10)
```

### Pattern 2: Meta Layer Pipeline
```python
# z03a_cognitive uses meta layer for intent classification
from zones.z07_data_access.meta_layer import MetaLayerPipeline

pipeline = MetaLayerPipeline()
result = pipeline.process(query="What drugs treat epilepsy?")
# Returns: {"intent": "drug_discovery", "entities": [...], "suggested_tools": [...]}
```

### Pattern 3: Entity Resolution
```python
# z03b_context uses resolvers for entity normalization
from zones.z07_data_access.meta_layer import GeneNameResolver, ChemicalResolver

gene_resolver = GeneNameResolver()
gene = gene_resolver.resolve("brca1")  # Returns BRCA1

chem_resolver = ChemicalResolver()
compound = chem_resolver.resolve("aspirin")  # Returns ChEMBL ID
```

### Pattern 4: Data Access Tools
```python
# z05_ml uses data access tools
from zones.z07_data_access.tools.graph_neighbors import get_graph_neighbors
from zones.z07_data_access.tools.drug_properties_detail import get_drug_properties

neighbors = get_graph_neighbors(entity_id="CHEMBL123", max_depth=2)
properties = get_drug_properties(drug_id="CHEMBL123")
```

---

## Boundary Violations to Avoid

### ❌ DON'T: Import from Higher Layers
```python
# WRONG - z07 cannot import from z03
from zones.z03b_context.context_manager import ContextManager  # ❌ VIOLATION

# CORRECT - z03 imports from z07
from zones.z07_data_access.embedding_service import EmbeddingService  # ✅ OK
```

### ❌ DON'T: Implement Database Clients
```python
# WRONG - Database client belongs in z08
import neo4j
driver = neo4j.GraphDatabase.driver("bolt://...")  # ❌ VIOLATION

# CORRECT - Use z08 client
from zones.z08_persist.neo4j_client import get_neo4j_client  # ✅ OK
client = get_neo4j_client()
```

### ❌ DON'T: Implement API Endpoints
```python
# WRONG - API endpoints belong in z09
from fastapi import APIRouter
router = APIRouter()

@router.get("/drugs/{drug_id}")  # ❌ VIOLATION
async def get_drug(drug_id: str):
    return service.get_drug(drug_id)

# CORRECT - z09 calls z07 service
# In z09:
from zones.z07_data_access import get_drug_service  # ✅ OK
```

### ❌ DON'T: Perform Data Loading
```python
# WRONG - Data loading belongs in z07_data_management
def load_drugs_from_csv(csv_path: str):  # ❌ VIOLATION
    df = pd.read_csv(csv_path)
    # Bulk insert into database

# CORRECT - z07 queries data, z07_data_management loads it
def query_drugs(drug_ids: List[str]):  # ✅ OK
    return client.query("MATCH (d:Drug) WHERE d.id IN $ids", ids=drug_ids)
```

### ✅ DO: Provide High-Level Query Services
```python
# CORRECT - High-level query service
class BBBPredictionService:  # ✅ OK
    def predict_from_smiles(self, smiles: str, k_neighbors: int = 10):
        """Predict BBB permeability from SMILES string."""
        # Uses ChemicalResolver, reference data, k-NN

    def predict_from_drug_name(self, drug_name: str, k_neighbors: int = 10):
        """Predict BBB permeability from drug name."""
        # Uses DrugNameResolver, ChemicalResolver, k-NN
```

---

## Data Flow

### Input Boundaries
```
z07 receives:
  ├─ Queries from z01 (UI requests)
  ├─ Entity names from z03a (cognitive processing)
  ├─ Search queries from z03b (context assembly)
  ├─ Feature requests from z05 (ML training)
  └─ Database connections from z08 (persistence layer)
```

### Output Boundaries
```
z07 provides:
  ├─ BBB predictions to z01 (presentation)
  ├─ Intent classifications to z03a (cognitive)
  ├─ Semantic search results to z03b (context)
  ├─ Feature vectors to z05 (ML)
  ├─ Query results to z02 (coordination)
  └─ Tool metadata to z04a (orchestration)
```

### External System Boundaries
```
z07 interacts with:
  ├─ Neo4j (via z08) - Knowledge graph queries
  ├─ PostgreSQL (via z08) - Vector embeddings, metadata
  ├─ RDKit - Chemical structure processing
  └─ LiteLLM/Anthropic - LLM-based query understanding
```

---

## Performance Boundaries

### Latency Targets
- **BBB Prediction**: <500ms (chemical similarity + k-NN)
  - Direct match: <10ms
  - Chemical similarity: 10-50ms
  - QSAR fallback: <150ms
- **PgVector Search**: <100ms (HNSW index)
- **Graph Queries**: <500ms (typical), <2s (complex)
- **Meta Layer**: <50ms (intent classification)
- **Resolvers**: <20ms (cached lookups)

### Resource Limits
- **Memory**: <2GB for reference datasets (6,497 BBB compounds, fingerprints)
- **Database Connections**: <20 concurrent (pooled via z08)
- **Cache Size**: <500MB (Morgan fingerprints, harmonizer dictionaries)
- **Concurrent Queries**: <50 simultaneous

### Throughput Targets
- **BBB Predictions**: 100 requests/sec (with cache)
- **Graph Queries**: 200 queries/sec
- **Vector Search**: 500 searches/sec
- **Entity Resolution**: 1,000 resolutions/sec

---

## Security Boundaries

### IN SCOPE
- ✅ Input validation (SMILES, drug names, query parameters)
- ✅ Query parameter sanitization (prevent Cypher injection)
- ✅ Safe deserialization of query results
- ✅ Credential masking in logs

### OUT OF SCOPE
- ❌ Authentication (belongs in z00_foundation/auth)
- ❌ Authorization (belongs in z04b_rules)
- ❌ API rate limiting (belongs in z09_integration)
- ❌ User session management (belongs in z01_presentation)

---

## Evolution Guidelines

### When to Add to z07
- ✅ New data access tool (query pattern used by 2+ zones)
- ✅ New query service (high-level abstraction over z08)
- ✅ New resolver (entity normalization for new data type)
- ✅ New feature extractor (for ML pipelines)

### When NOT to Add to z07
- ❌ Raw database operations (add to z08)
- ❌ Data loading scripts (add to z07_data_management)
- ❌ ML model code (add to z05_ml)
- ❌ API endpoints (add to z09)

### Migration Path for New Tools
1. **Prototype**: Create in local zone (e.g., z03b)
2. **Validate**: Use by 2+ zones
3. **Migrate**: Move to z07/tools/ if query-focused
4. **Document**: Add to tool registry
5. **Test**: Add integration tests

### Tool Complexity Threshold
- **Simple tool** (<100 lines): Keep in z07/tools/
- **Complex service** (>500 lines): Promote to z07/ root
- **ML-heavy** (model training): Move to z05_ml
- **ETL-heavy** (data loading): Move to z07_data_management

---

## Compliance & Governance

### Architectural Compliance
- ✅ Follows layered architecture (Layer 5)
- ✅ No upward dependencies (except controlled z05_models exception)
- ✅ Clean separation from presentation (z01) and business (z02)
- ✅ Single Responsibility: Data access only

### Documentation Requirements
- ✅ ZONE_INTENT.md (zone purpose) - COMPLETE
- ✅ BOUNDARIES.md (this file) - COMPLETE
- ✅ INTERFACES.md (public API) - IN PROGRESS
- ✅ README.md (getting started) - PLANNED
- ✅ 148 tool docstrings (implementation-level)

### Testing Requirements
- ✅ 24 test files (third-highest in system)
- ✅ BBBPredictionService: 100% coverage (23 tests, A+ quality)
- ✅ >90% test coverage target
- ✅ Integration tests with Neo4j/PostgreSQL
- ✅ Performance benchmarks for critical paths

### Quality Gates
- ✅ All services have type hints (>95% coverage)
- ✅ All resolvers tested with real data
- ✅ BBB service: <500ms prediction (99th percentile)
- ✅ No direct database imports (use z08 only)

---

## Enforcement

### Pre-commit Checks
- Check for upward dependencies (block z01-z06 imports)
- Validate imports from allowed zones only (z00, z08, z10c)
- Ensure no API endpoint definitions (FastAPI, gRPC)
- Verify tool docstrings present

### Runtime Checks
- Log boundary violations (unexpected import attempts)
- Monitor performance targets (BBB <500ms, queries <2s)
- Track database connection limits (<20 concurrent)
- Alert on cache size limits (>500MB)

### Code Review Checklist
- [ ] No imports from z01-z06 (except z05_models/bbb_qsar_model.py)
- [ ] Uses z08 for database access (not direct clients)
- [ ] Query logic only (no ETL, no training, no endpoints)
- [ ] Type hints present (Pydantic models preferred)
- [ ] Tests included (unit + integration)
- [ ] Performance tested (if critical path)

---

## Special Cases & Exceptions

### Exception 1: z05_models/bbb_qsar_model.py
**Context**: BBBPredictionService needs QSAR fallback when no similar chemicals found.

**Exception**: Allow optional import from z05_models.bbb_qsar_model
```python
try:
    from z05_models.bbb_qsar_model import get_bbb_qsar_model
    ML_QSAR_AVAILABLE = True
except ImportError:
    ML_QSAR_AVAILABLE = False
```

**Justification**:
- QSAR model is read-only inference (not training)
- Graceful degradation if z05 not available
- Prevents circular dependency (z05 doesn't import z07)
- Limited scope (one file, one function)

**Governance**: Approved by Platform Architecture Team (2025-12-01)

### Exception 2: Meta Layer LLM Usage
**Context**: IntentClassifier uses LLM for query understanding.

**Allowed**: LiteLLMAnthropicClient in z07 (wraps z00 config)
**Justification**: Query understanding is data access concern (not cognitive)

### Exception 3: RDKit Dependency
**Context**: ChemicalResolver needs chemical structure processing.

**Allowed**: Direct RDKit usage for Morgan fingerprints, SMILES parsing
**Justification**: Essential for chemical similarity, no alternative in z08

---

## Boundary Success Metrics

### Immediate (Today)
- [x] ZONE_INTENT.md complete
- [x] BOUNDARIES.md complete (this file)
- [ ] INTERFACES.md complete
- [ ] README.md complete
- [ ] All 24 tests passing

### Week 1
- [ ] No boundary violations in imports
- [ ] All 148 tools documented
- [ ] >90% test coverage
- [ ] Performance benchmarks green

### Month 1
- [ ] All zones using z07 for data access (not z08 directly)
- [ ] BBB service integrated in z01, z03b, z05
- [ ] Meta layer used by z03a cognitive agent
- [ ] Zero boundary violations in production

---

**Document Owner**: Colonel z07_data_access
**Reviewers**: Platform Architecture Team
**Approved By**: Platform General
**Last Validated**: 2025-12-02
**Next Review**: 2025-12-09
**Status**: ACTIVE
