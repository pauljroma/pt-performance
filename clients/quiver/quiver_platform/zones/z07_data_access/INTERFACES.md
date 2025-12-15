# Zone Interfaces: z07_data_access

**Zone**: z07_data_access (Data Access Layer)
**Layer**: Layer 5 (Data & Integration)
**Total Components**: 149 Python files
**Last Updated**: 2025-12-02

---

## Public API Overview

z07_data_access provides data access services organized into 6 major categories:

1. **Query Services** - High-level data operations (BBB, PgVector, Embedding, MOA)
2. **Meta Layer** - Query understanding and entity resolution
3. **Resolvers** - Entity normalization (Gene, Chemical, Drug, Disease, Pathway)
4. **Data Access Tools** - 46 specialized query tools
5. **Feature Extraction** - Graph and drug feature extractors
6. **Database Wrappers** - LiteLLM and connection helpers

---

## 1. Query Services

### 1.1 BBBPredictionService (A+ Production Quality)

**Module**: `zones.z07_data_access.bbb_prediction_service`

```python
from zones.z07_data_access.bbb_prediction_service import (
    get_bbb_prediction_service,
    BBBPredictionService,
    BBBPrediction
)

service = get_bbb_prediction_service()

# Predict from SMILES
prediction: BBBPrediction = service.predict_from_smiles(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',  # Caffeine
    drug_name='Caffeine',
    k_neighbors=10
)

# Predict from drug name
prediction: BBBPrediction = service.predict_from_drug_name(
    drug_name='Fenfluramine',
    k_neighbors=10
)

# Batch prediction
drugs = [
    {'smiles': 'CC(C)NCC(COc1ccccc1)O', 'drug_name': 'Propranolol'},
    {'smiles': 'CN1C=NC2=C1C(=O)N(C(=O)N2C)C', 'drug_name': 'Caffeine'}
]
predictions: List[BBBPrediction] = service.batch_predict(drugs, k_neighbors=10)

# Get statistics
stats = service.get_stats()
# Returns: {
#     'reference_compounds': 6497,
#     'literature_validated': 39,
#     'qsar_predicted': 6458,
#     'cache_size': 6497,
#     'cache_hit_rate': 0.85
# }
```

**BBBPrediction Dataclass**:
```python
@dataclass
class BBBPrediction:
    drug_name: str
    chembl_id: Optional[str]
    smiles: str
    predicted_log_bb: float  # Log(BBB permeability ratio)
    predicted_bbb_class: str  # "BBB+", "BBB-", or "uncertain"
    confidence: float  # 0.0-1.0
    prediction_method: str  # "chemical_similarity", "direct_match", "qsar_fallback"
    nearest_neighbors: List[Dict[str, Any]]  # K most similar compounds
    metadata: Dict[str, Any]
```

**Performance**:
- Direct match: <10ms (exact SMILES in reference data)
- Chemical similarity: 10-50ms (k-NN weighted average)
- QSAR fallback: <150ms (ML model inference)
- Accuracy: 80-85% (validated against literature)

---

### 1.2 PgVectorService

**Module**: `zones.z07_data_access.pgvector_service`

```python
from zones.z07_data_access.pgvector_service import (
    PgVectorService,
    RescueResult,
    SimilarityResult
)

service = PgVectorService()

# Semantic search for drug embeddings
results: List[SimilarityResult] = service.search_similar_drugs(
    drug_name="Fenfluramine",
    embedding_space="DFP_PhaseII_16D_v1_0",
    top_k=20,
    similarity_threshold=0.5
)

# Antipodal search (rescue drug discovery)
rescue_results: List[RescueResult] = service.find_rescue_drugs(
    gene_symbol="SCN1A",
    embedding_space="MODEX_Gene_16D_v2_0",
    top_k=50,
    rescue_threshold=0.7
)

# Gene similarity search
gene_results: List[SimilarityResult] = service.search_similar_genes(
    gene_symbol="SCN1A",
    embedding_space="MODEX_Gene_16D_v2_0",
    top_k=20
)

# Get available embedding spaces
spaces = service.get_available_spaces()
# Returns: ['MODEX_Gene_16D_v2_0', 'DFP_PhaseII_16D_v1_0', 'PLATINUM_QNVS_v2_0', ...]
```

**Performance**:
- HNSW index queries: <100ms
- Antipodal search: <200ms
- Embedding dimensions: 16D (MODEX), 32D (legacy)

---

### 1.3 EmbeddingService

**Module**: `zones.z07_data_access.embedding_service`

```python
from zones.z07_data_access.embedding_service import (
    EmbeddingService,
    EmbeddingConfig
)

service = EmbeddingService()

# Load embeddings from file
embeddings = service.load_embeddings(
    space_name="lincs_drug_32d_v5_0",
    format="npz"  # or "parquet"
)

# Get embedding for specific entity
drug_embedding = service.get_embedding(
    entity_name="Fenfluramine",
    space_name="lincs_drug_32d_v5_0"
)

# Search similar entities
similar = service.find_similar(
    entity_name="Fenfluramine",
    space_name="lincs_drug_32d_v5_0",
    top_k=20
)

# List available embedding spaces
spaces = service.list_spaces()
```

---

### 1.4 MOAExpansionService

**Module**: `zones.z07_data_access.moa_expansion_service`

```python
from zones.z07_data_access.moa_expansion_service import (
    MOAExpansionService,
    MOAResult
)

service = MOAExpansionService()

# Expand mechanism of action for drug
moa_results: List[MOAResult] = service.expand_moa(
    drug_name="Fenfluramine",
    include_pathways=True,
    include_targets=True
)

# Get MOA statistics
stats = service.get_moa_stats(drug_name="Fenfluramine")
```

---

## 2. Meta Layer (Query Understanding)

### 2.1 MetaLayerPipeline

**Module**: `zones.z07_data_access.meta_layer`

```python
from zones.z07_data_access.meta_layer import (
    MetaLayerPipeline,
    get_meta_layer_pipeline
)

pipeline = get_meta_layer_pipeline()

# Process natural language query
result = pipeline.process(
    question="Find rescue drugs for epilepsy gene SCN1A",
    category="rescue"
)

# Returns:
# {
#     'entities': [
#         {'entity': 'SCN1A', 'type': 'gene', 'confidence': 0.90}
#     ],
#     'intent': {
#         'intent': 'gene_to_drug_rescue',
#         'tool': 'rescue_combinations',
#         'primary_space': 'lincs_drug_32d_v5_0',
#         'confidence': 0.90
#     },
#     'query_params': {
#         'entity_name': 'SCN1A',
#         'entity_type': 'gene',
#         'preferred_space': 'lincs_drug_32d_v5_0',
#         'k': 50
#     },
#     'pipeline_metadata': {
#         'stages_executed': ['fuzzy_entity_matcher', 'intent_classifier'],
#         'total_latency_ms': 12.5,
#         'confidence': 0.90
#     }
# }
```

**Performance**: <20ms pipeline total

---

### 2.2 IntentClassifier

**Module**: `zones.z07_data_access.meta_layer.classifiers`

```python
from zones.z07_data_access.meta_layer.classifiers import (
    get_intent_classifier,
    IntentClassifier
)

classifier = get_intent_classifier()

# Classify query intent
intent = classifier.classify(
    "What is the mechanism of action for gabapentin?"
)

# Returns:
# {
#     'intent': 'mechanism_lookup',
#     'tool': 'mechanistic_explainer',
#     'primary_space': 'mop_emb_15d_v5_0',
#     'query_type': 'lookup',
#     'confidence': 0.90
# }
```

**Supported Intents**:
- `drug_discovery` - Find drugs for disease/target
- `gene_to_drug_rescue` - Find rescue drugs for gene
- `drug_similarity` - Find similar drugs
- `mechanism_lookup` - Get drug mechanism of action
- `pathway_analysis` - Analyze pathways
- `biomarker_discovery` - Find biomarkers
- `clinical_trial` - Clinical trial search
- `literature_search` - Literature evidence
- ...and 23 more

---

## 3. Resolvers (Entity Normalization)

### 3.1 GeneNameResolver

**Module**: `zones.z07_data_access.meta_layer.resolvers`

```python
from zones.z07_data_access.meta_layer.resolvers import (
    get_gene_name_resolver,
    GeneNameResolver
)

resolver = get_gene_name_resolver()

# Resolve gene symbol to standard HGNC
gene = resolver.resolve("brca1")
# Returns: {
#     'symbol': 'BRCA1',
#     'ensembl_id': 'ENSG00000012048',
#     'hgnc_id': 'HGNC:1100',
#     'aliases': ['BRCA-1', 'IRIS'],
#     'confidence': 1.0
# }

# Batch resolution
genes = resolver.batch_resolve(["scn1a", "kcnq2", "brca1"])

# Get gene statistics
stats = resolver.get_stats()
```

**Performance**: <10ms per resolution (cached)

---

### 3.2 ChemicalResolver

**Module**: `zones.z07_data_access.meta_layer.resolvers`

```python
from zones.z07_data_access.meta_layer.resolvers import (
    get_chemical_resolver,
    ChemicalResolver
)

resolver = get_chemical_resolver()

# Resolve chemical structure
compound = resolver.resolve("aspirin")
# Returns: {
#     'chembl_id': 'CHEMBL25',
#     'smiles': 'CC(=O)Oc1ccccc1C(=O)O',
#     'inchi': 'InChI=1S/C9H8O4/c1-6(10)13-8-5-3-2-4-7(8)9(11)12/h2-5H,1H3,(H,11,12)',
#     'synonyms': ['aspirin', 'acetylsalicylic acid', 'ASA'],
#     'confidence': 1.0
# }

# Calculate Tanimoto similarity
similarity = resolver.calculate_similarity(
    smiles1='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',  # Caffeine
    smiles2='CC(C)NCC(COc1ccccc1)O'  # Propranolol
)
# Returns: 0.23 (Tanimoto coefficient)

# Find similar chemicals
similar = resolver.find_similar(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
    top_k=20,
    similarity_threshold=0.7
)
```

**Performance**: <50ms (with fingerprint caching)

---

### 3.3 DrugNameResolver

**Module**: `zones.z07_data_access.meta_layer.resolvers`

```python
from zones.z07_data_access.meta_layer.resolvers import (
    get_drug_name_resolver,
    DrugNameResolver
)

resolver = get_drug_name_resolver()

# Resolve drug name to standard identifier
drug = resolver.resolve("fenfluramine")
# Returns: {
#     'drug_name': 'Fenfluramine',
#     'qs_id': 'QS1410108',
#     'chembl_id': 'CHEMBL809',
#     'smiles': 'CCNC(C)Cc1cccc(c1)C(F)(F)F',
#     'synonyms': ['fintepla', 'd-fenfluramine'],
#     'confidence': 1.0
# }

# QS code to commercial name
commercial = resolver.qs_to_commercial("QS1410108")
# Returns: "Fenfluramine"

# Batch resolution
drugs = resolver.batch_resolve(["aspirin", "ibuprofen", "fenfluramine"])
```

**Performance**: <10ms per resolution (multi-source fallback)

---

### 3.4 DiseaseResolver

**Module**: `zones.z07_data_access.meta_layer.resolvers`

```python
from zones.z07_data_access.meta_layer.resolvers import (
    get_disease_resolver,
    DiseaseResolver
)

resolver = get_disease_resolver()

# Resolve disease name
disease = resolver.resolve("epilepsy")
# Returns: {
#     'disease_name': 'Epilepsy',
#     'mondo_id': 'MONDO:0005027',
#     'efo_id': 'EFO:0000474',
#     'icd10': 'G40',
#     'synonyms': ['seizure disorder', 'convulsive disorder'],
#     'confidence': 1.0
# }
```

---

### 3.5 PathwayResolver

**Module**: `zones.z07_data_access.meta_layer.resolvers`

```python
from zones.z07_data_access.meta_layer.resolvers import (
    get_pathway_resolver,
    PathwayResolver
)

resolver = get_pathway_resolver()

# Resolve pathway
pathway = resolver.resolve("GABAergic synapse")
# Returns: {
#     'pathway_name': 'GABAergic synapse',
#     'reactome_id': 'R-HSA-977443',
#     'kegg_id': 'hsa04727',
#     'genes': ['GABRA1', 'GABRA2', ...],
#     'confidence': 1.0
# }
```

---

## 4. Data Access Tools (46 Tools)

### Graph Query Tools

#### 4.1 graph_neighbors
**Module**: `zones.z07_data_access.tools.graph_neighbors`

Find neighboring nodes in Neo4j knowledge graph.

```python
from zones.z07_data_access.tools.graph_neighbors import get_graph_neighbors

neighbors = get_graph_neighbors(
    entity_id="CHEMBL123",
    max_depth=2,
    relationship_types=["TARGETS", "TREATS"],
    limit=20
)
```

#### 4.2 graph_path
**Module**: `zones.z07_data_access.tools.graph_path`

Find shortest paths between entities in graph.

```python
from zones.z07_data_access.tools.graph_path import find_graph_path

paths = find_graph_path(
    start_id="CHEMBL123",
    end_id="SCN1A",
    max_length=4,
    limit=10
)
```

#### 4.3 graph_subgraph
**Module**: `zones.z07_data_access.tools.graph_subgraph`

Extract subgraph around entity.

```python
from zones.z07_data_access.tools.graph_subgraph import extract_subgraph

subgraph = extract_subgraph(
    entity_id="SCN1A",
    radius=2,
    node_labels=["Drug", "Gene", "Disease"]
)
```

#### 4.4 graph_properties
**Module**: `zones.z07_data_access.tools.graph_properties`

Get node/edge properties.

```python
from zones.z07_data_access.tools.graph_properties import get_graph_properties

properties = get_graph_properties(
    entity_id="CHEMBL123",
    include_relationships=True
)
```

---

### Similarity Search Tools

#### 4.5 semantic_search
**Module**: `zones.z07_data_access.tools.semantic_search`

Semantic similarity search across embeddings.

```python
from zones.z07_data_access.tools.semantic_search import semantic_search

results = semantic_search(
    query="epilepsy treatment",
    embedding_space="lincs_drug_32d_v5_0",
    top_k=20,
    similarity_threshold=0.5
)
```

#### 4.6 vector_similarity
**Module**: `zones.z07_data_access.tools.vector_similarity`

Calculate vector similarity between entities.

```python
from zones.z07_data_access.tools.vector_similarity import calculate_vector_similarity

similarity = calculate_vector_similarity(
    entity1="Fenfluramine",
    entity2="Valproic Acid",
    embedding_space="lincs_drug_32d_v5_0"
)
```

#### 4.7 vector_neighbors
**Module**: `zones.z07_data_access.tools.vector_neighbors`

Find k-nearest neighbors in embedding space.

```python
from zones.z07_data_access.tools.vector_neighbors import find_vector_neighbors

neighbors = find_vector_neighbors(
    entity_name="Fenfluramine",
    embedding_space="lincs_drug_32d_v5_0",
    k=20
)
```

#### 4.8 vector_antipodal
**Module**: `zones.z07_data_access.tools.vector_antipodal`

Find antipodal (opposite) vectors for rescue drug discovery.

```python
from zones.z07_data_access.tools.vector_antipodal import find_antipodal_vectors

antipodal = find_antipodal_vectors(
    gene_symbol="SCN1A",
    embedding_space="MODEX_Gene_16D_v2_0",
    top_k=50
)
```

---

### Drug Discovery Tools

#### 4.9 drug_properties_detail
**Module**: `zones.z07_data_access.tools.drug_properties_detail`

Get detailed drug properties.

```python
from zones.z07_data_access.tools.drug_properties_detail import get_drug_properties

properties = get_drug_properties(
    drug_id="CHEMBL123",
    include_targets=True,
    include_pathways=True
)
```

#### 4.10 drug_lookalikes
**Module**: `zones.z07_data_access.tools.drug_lookalikes`

Find structurally similar drugs.

```python
from zones.z07_data_access.tools.drug_lookalikes import find_drug_lookalikes

similar_drugs = find_drug_lookalikes(
    drug_name="Fenfluramine",
    similarity_threshold=0.7,
    top_k=20
)
```

#### 4.11 drug_interactions
**Module**: `zones.z07_data_access.tools.drug_interactions`

Query drug-drug interactions.

```python
from zones.z07_data_access.tools.drug_interactions import get_drug_interactions

interactions = get_drug_interactions(
    drug_name="Fenfluramine",
    interaction_type="all"  # or "major", "moderate", "minor"
)
```

#### 4.12 drug_combinations_synergy
**Module**: `zones.z07_data_access.tools.drug_combinations_synergy`

Analyze drug combination synergy.

```python
from zones.z07_data_access.tools.drug_combinations_synergy import analyze_synergy

synergy = analyze_synergy(
    drug1="Fenfluramine",
    drug2="Valproic Acid",
    disease="Epilepsy"
)
```

#### 4.13 rescue_combinations
**Module**: `zones.z07_data_access.tools.rescue_combinations`

Find rescue drug combinations for genetic diseases.

```python
from zones.z07_data_access.tools.rescue_combinations import find_rescue_combinations

rescue_drugs = find_rescue_combinations(
    gene_symbol="SCN1A",
    disease="Dravet Syndrome",
    embedding_space="lincs_drug_32d_v5_0",
    top_k=50
)
```

#### 4.14 drug_repurposing_ranker
**Module**: `zones.z07_data_access.tools.drug_repurposing_ranker`

Rank drugs for repurposing opportunities.

```python
from zones.z07_data_access.tools.drug_repurposing_ranker import rank_repurposing

ranked = rank_repurposing(
    disease="Epilepsy",
    criteria=["safety", "efficacy", "novelty"],
    top_k=50
)
```

---

### Literature & Evidence Tools

#### 4.15 literature_evidence
**Module**: `zones.z07_data_access.tools.literature_evidence`

Search literature for evidence.

```python
from zones.z07_data_access.tools.literature_evidence import search_literature

evidence = search_literature(
    query="Fenfluramine epilepsy",
    sources=["PubMed", "ClinicalTrials.gov"],
    limit=50
)
```

#### 4.16 literature_search_agent
**Module**: `zones.z07_data_access.tools.literature_search_agent`

AI-powered literature search.

```python
from zones.z07_data_access.tools.literature_search_agent import search_literature_agent

results = search_literature_agent(
    question="What is the mechanism of fenfluramine in Dravet syndrome?",
    max_papers=20
)
```

#### 4.17 provenance_discovery
**Module**: `zones.z07_data_access.tools.provenance_discovery`

Discover data provenance and lineage.

```python
from zones.z07_data_access.tools.provenance_discovery import discover_provenance

provenance = discover_provenance(
    entity_id="CHEMBL123",
    trace_depth=3
)
```

#### 4.18 mechanistic_explainer
**Module**: `zones.z07_data_access.tools.mechanistic_explainer`

Explain drug mechanism of action.

```python
from zones.z07_data_access.tools.mechanistic_explainer import explain_mechanism

mechanism = explain_mechanism(
    drug_name="Fenfluramine",
    include_pathways=True,
    include_targets=True
)
```

---

### Expression & Transcriptomics Tools

#### 4.19 lincs_expression_detail
**Module**: `zones.z07_data_access.tools.lincs_expression_detail`

Get LINCS expression profile details.

```python
from zones.z07_data_access.tools.lincs_expression_detail import get_lincs_expression

expression = get_lincs_expression(
    drug_name="Fenfluramine",
    cell_line="MCF7",
    dose="10uM"
)
```

#### 4.20 transcriptomic_rescue
**Module**: `zones.z07_data_access.tools.transcriptomic_rescue`

Find transcriptomic rescue candidates.

```python
from zones.z07_data_access.tools.transcriptomic_rescue import find_transcriptomic_rescue

rescue = find_transcriptomic_rescue(
    gene_signature=["SCN1A", "KCNQ2", "GABRA1"],
    cell_line="neurons",
    top_k=50
)
```

---

### Biomarker & Causal Analysis Tools

#### 4.21 biomarker_discovery
**Module**: `zones.z07_data_access.tools.biomarker_discovery`

Discover biomarkers for disease.

```python
from zones.z07_data_access.tools.biomarker_discovery import discover_biomarkers

biomarkers = discover_biomarkers(
    disease="Dravet Syndrome",
    biomarker_type="protein",  # or "gene", "metabolite"
    top_k=20
)
```

#### 4.22 causal_inference
**Module**: `zones.z07_data_access.tools.causal_inference`

Perform causal relationship analysis.

```python
from zones.z07_data_access.tools.causal_inference import infer_causality

causality = infer_causality(
    cause="SCN1A mutation",
    effect="Epilepsy",
    method="mendelian_randomization"
)
```

---

### ADME/Tox & Target Validation Tools

#### 4.23 adme_tox_predictor
**Module**: `zones.z07_data_access.tools.adme_tox_predictor`

Predict ADME/Tox properties.

```python
from zones.z07_data_access.tools.adme_tox_predictor import predict_adme_tox

adme = predict_adme_tox(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
    properties=["solubility", "clearance", "toxicity"]
)
```

#### 4.24 bbb_permeability
**Module**: `zones.z07_data_access.tools.bbb_permeability`

Predict blood-brain barrier permeability.

```python
from zones.z07_data_access.tools.bbb_permeability import predict_bbb

bbb = predict_bbb(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
    method="chemical_similarity"  # or "qsar"
)
```

#### 4.25 target_validation_scorer
**Module**: `zones.z07_data_access.tools.target_validation_scorer`

Score target validation for drug development.

```python
from zones.z07_data_access.tools.target_validation_scorer import score_target

score = score_target(
    target_gene="SCN1A",
    disease="Epilepsy",
    criteria=["genetic_evidence", "pathway_relevance", "druggability"]
)
```

---

### Clinical Trial & Scientist Reports

#### 4.26 clinical_trial_intelligence
**Module**: `zones.z07_data_access.tools.clinical_trial_intelligence`

Query clinical trial data.

```python
from zones.z07_data_access.tools.clinical_trial_intelligence import query_clinical_trials

trials = query_clinical_trials(
    drug_name="Fenfluramine",
    disease="Dravet Syndrome",
    phase=["Phase 3", "Phase 4"],
    status="Completed"
)
```

#### 4.27 scientist_reports
**Module**: `zones.z07_data_access.tools.scientist_reports`

Generate scientist-friendly reports.

```python
from zones.z07_data_access.tools.scientist_reports import generate_report

report = generate_report(
    topic="Fenfluramine in Dravet Syndrome",
    sections=["mechanism", "clinical_trials", "safety"],
    format="markdown"
)
```

---

### System Utilities

#### 4.28 count_entities
**Module**: `zones.z07_data_access.tools.count_entities`

Count entities in knowledge graph.

```python
from zones.z07_data_access.tools.count_entities import count_entities

counts = count_entities(
    entity_types=["Drug", "Gene", "Disease", "Pathway"]
)
# Returns: {'Drug': 12500, 'Gene': 19000, 'Disease': 8000, 'Pathway': 2500}
```

#### 4.29 entity_metadata
**Module**: `zones.z07_data_access.tools.entity_metadata`

Get entity metadata.

```python
from zones.z07_data_access.tools.entity_metadata import get_entity_metadata

metadata = get_entity_metadata(
    entity_id="CHEMBL123",
    include_provenance=True
)
```

#### 4.30 available_spaces
**Module**: `zones.z07_data_access.tools.available_spaces`

List available embedding spaces.

```python
from zones.z07_data_access.tools.available_spaces import list_available_spaces

spaces = list_available_spaces(
    entity_type="drug",  # or "gene", "disease"
    source="pgvector"  # or "file"
)
```

#### 4.31 execute_cypher
**Module**: `zones.z07_data_access.tools.execute_cypher`

Execute custom Cypher queries (advanced).

```python
from zones.z07_data_access.tools.execute_cypher import execute_cypher

results = execute_cypher(
    query="MATCH (d:Drug)-[:TARGETS]->(g:Gene) WHERE g.symbol = 'SCN1A' RETURN d",
    parameters={}
)
```

---

### Additional Tools (4.32-4.46)

**Query Orchestration**:
- `query_direct_run` - Direct query execution
- `query_atomic_fusion` - Atomic query fusion
- `query_unified_orchestration` - Unified query orchestration
- `fusion_query_utils` - Query fusion utilities

**File Operations**:
- `read_parquet_filter` - Read and filter Parquet files

**Vector Operations**:
- `vector_dimensions` - Get embedding dimensions

**Session & Analytics**:
- `session_analytics` - Session analytics
- `semantic_collections` - Manage semantic collections

**Uncertainty & Validation**:
- `uncertainty_estimation` - Estimate prediction uncertainty
- `validate_moa_expansion` - Validate MOA expansion

**Test Tools** (internal):
- `test_bbb_knn` - Test BBB k-NN
- `test_bbb_simple` - Test BBB simple
- `test_vector_neighbors` - Test vector neighbors

**Registration**:
- `register_cns_tools` - Register CNS tools

---

## 5. Feature Extraction

### 5.1 GraphFeatureExtractor

**Module**: `zones.z07_data_access.tool_utils`

```python
from zones.z07_data_access.tool_utils import GraphFeatureExtractor

extractor = GraphFeatureExtractor()

# Extract graph features for entity
features = extractor.extract(
    entity_id="CHEMBL123",
    feature_types=["degree", "betweenness", "pagerank"]
)
```

### 5.2 DrugFeatureExtractor

**Module**: `zones.z07_data_access.tool_utils`

```python
from zones.z07_data_access.tool_utils import DrugFeatureExtractor

extractor = DrugFeatureExtractor()

# Extract chemical features from SMILES
features = extractor.extract(
    smiles='CN1C=NC2=C1C(=O)N(C(=O)N2C)C',
    feature_types=["morgan_fp", "descriptors", "properties"]
)
```

---

## 6. Database Wrappers

### 6.1 LiteLLMAnthropicClient

**Module**: `zones.z07_data_access.litellm_anthropic_bridge`

```python
from zones.z07_data_access.litellm_anthropic_bridge import LiteLLMAnthropicClient

client = LiteLLMAnthropicClient()

# Generate completion
response = client.complete(
    prompt="What is the mechanism of fenfluramine?",
    model="claude-3-sonnet-20240229",
    max_tokens=1000
)
```

---

## Performance Characteristics

| Service/Tool | Latency (p50) | Latency (p99) | Throughput |
|--------------|---------------|---------------|------------|
| BBBPredictionService | 20ms | 500ms | 100 req/sec |
| PgVectorService | 50ms | 100ms | 500 req/sec |
| GeneNameResolver | 5ms | 20ms | 1000 req/sec |
| ChemicalResolver | 20ms | 50ms | 200 req/sec |
| MetaLayerPipeline | 10ms | 20ms | 500 req/sec |
| graph_neighbors | 100ms | 500ms | 200 req/sec |
| semantic_search | 50ms | 100ms | 500 req/sec |
| rescue_combinations | 200ms | 2000ms | 50 req/sec |

---

## Error Handling

All services and tools follow consistent error handling patterns:

```python
# Return None for not found
result = resolver.resolve("unknown_entity")  # Returns None

# Raise ValueError for invalid input
service.predict_from_smiles("invalid_smiles")  # Raises ValueError

# Return empty list for no results
results = tool.find_neighbors("entity_123")  # Returns []

# Log errors and return gracefully
try:
    result = service.complex_operation()
except Exception as e:
    logger.error("Operation failed", error=str(e), exc_info=True)
    return {"status": "error", "message": str(e)}
```

---

## Testing

### Running Tests
```bash
# Run all z07 tests
pytest quiver_platform/zones/z07_data_access/tests/ -v

# Run specific test module
pytest quiver_platform/zones/z07_data_access/tests/test_bbb_service.py -v

# Run with coverage
pytest --cov=zones.z07_data_access --cov-report=html quiver_platform/zones/z07_data_access/tests/
```

### Test Coverage
- **Total Test Files**: 24 (third-highest in system)
- **BBB Service**: 100% coverage (23 tests, A+ quality)
- **Target**: >90% line coverage
- **Status**: EXCELLENT

---

## API Stability

**Stability**: DEVELOPING → MATURE

- ✅ Core services (BBB, PgVector) are STABLE
- ✅ Meta layer is STABLE (v1.0.0)
- ✅ Resolvers are STABLE
- ⚠️  Some tools are EXPERIMENTAL (marked in docstrings)
- ✅ Deprecation warnings before breaking changes
- ✅ Backward compatibility maintained for stable APIs

---

## Integration Points

### Zone 01 (Presentation)
```python
# Uses BBB service for predictions
from zones.z07_data_access.bbb_prediction_service import get_bbb_prediction_service
```

### Zone 03a (Cognitive)
```python
# Uses meta layer for intent classification
from zones.z07_data_access.meta_layer import MetaLayerPipeline
```

### Zone 03b (Context)
```python
# Uses embedding service and semantic search
from zones.z07_data_access.embedding_service import EmbeddingService
from zones.z07_data_access.tools.semantic_search import semantic_search
```

### Zone 05 (ML)
```python
# Uses feature extractors
from zones.z07_data_access.tool_utils import GraphFeatureExtractor, DrugFeatureExtractor
```

---

## Dependencies

### Required
- Python 3.11+
- rdkit-pypi >= 2023.9.1
- pandas >= 1.5.0
- numpy >= 1.24.0
- psycopg2 >= 2.9
- neo4j >= 5.0

### Optional
- litellm (for LLM integration)
- chromadb (for vector storage)

---

**Document Owner**: Colonel z07_data_access
**API Version**: 2.0
**Last Updated**: 2025-12-02
**Next Review**: 2025-12-09
