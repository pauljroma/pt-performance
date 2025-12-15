# BBB Dataset Expansion Plan

**Current Dataset:** 6,497 compounds (36 literature-validated, 6,461 QSAR-predicted)
**Target:** 10,000+ compounds (500+ literature-validated)
**Quality Requirement:** Maintain A+ quality, prioritize experimental data

---

## Strategy Overview

### 3-Tier Expansion Approach

1. **Tier 1: Literature Mining** (Target: +300 compounds)
   - Highest quality: experimental BBB data
   - Priority: Published papers, clinical data

2. **Tier 2: Database Integration** (Target: +2,000 compounds)
   - Medium quality: curated databases
   - Sources: DrugBank, PubChem, specialized BBB databases

3. **Tier 3: Validated QSAR Predictions** (Target: +1,000 compounds)
   - Computed data with validation
   - Filter by prediction confidence

---

## Tier 1: Literature Mining (Highest Priority)

### 1.1 Scientific Literature Sources

**PubMed/PubMed Central:**
- Query: `"blood-brain barrier" AND ("log BB" OR "brain/plasma ratio" OR "Kp,brain")`
- Focus: Papers with experimental data tables
- Extraction: Manual or semi-automated (PubTator)

**Key Journals:**
- Journal of Medicinal Chemistry
- Journal of Pharmacology and Experimental Therapeutics
- Drug Metabolism and Disposition
- Molecular Pharmaceutics

**Implementation:**
```python
# Script: mine_pubmed_bbb_data.py
from Bio import Entrez
import xml.etree.ElementTree as ET

def search_pubmed_bbb():
    Entrez.email = "your.email@example.com"
    query = '"blood-brain barrier"[Title/Abstract] AND ("log BB"[Text] OR "brain plasma ratio"[Text])'

    handle = Entrez.esearch(db="pubmed", term=query, retmax=1000)
    results = Entrez.read(handle)

    return results['IdList']

def extract_bbb_tables(pubmed_id):
    # Download full text if available (PMC)
    # Extract tables with BBB data
    # Parse compounds and log BB values
    pass
```

### 1.2 Existing BBB Databases

**B3DB (Blood-Brain Barrier Database):**
- URL: https://www.docking.org/b3db
- Contains: ~7,500 compounds with experimental BBB data
- Format: SDF files with properties
- **Action:** Download and integrate

**BBBP Dataset (MoleculeNet):**
- Source: Martins et al., 2012
- Contains: 2,050 compounds (experimental BBB penetration)
- Binary classification (BBB+ / BBB-)
- **Action:** Download from MoleculeNet, extract Log BB values if available

**ADMETlab Database:**
- URL: https://admet.scbdd.com
- Contains: BBB permeability predictions with experimental validation
- **Action:** Extract experimental subset

### 1.3 Clinical Pharmacology Data

**DrugBank:**
- Contains: ~15,000 drugs with pharmacokinetic data
- BBB data: Some drugs have brain/plasma ratios
- **Action:** Parse XML, extract CNS drugs with PK data

**FDA Drug Labels:**
- Contains: CNS penetration data for approved drugs
- Format: Structured Product Labels (SPL)
- **Action:** Parse SPL XML for CNS penetration mentions

---

## Tier 2: Database Integration

### 2.1 ChEMBL Expansion

**Current:** Already using ChEMBL BBB data
**Expansion:** Mine related assays

```python
# Script: expand_chembl_bbb.py
from chembl_webresource_client.new_client import new_client

# Search for BBB-related assays
activity = new_client.activity

# Assay types to search:
assays_to_search = [
    'Brain penetration',
    'CNS penetration',
    'Brain/plasma ratio',
    'Kp,brain',
    'P-glycoprotein substrate',  # Related to BBB efflux
    'MDR1 substrate'
]

for assay_term in assays_to_search:
    results = activity.filter(
        assay_description__icontains=assay_term,
        standard_type__in=['Kp', 'Ratio', 'Log BB']
    )
```

### 2.2 PubChem BioAssay

**AID 1851 (BBB Permeability Assay):**
- Contains: MDR1-MDCK permeability data
- Surrogate for BBB permeability
- **Action:** Download and convert to Log BB estimates

**Implementation:**
```python
import pubchempy as pcp

# Search for BBB-related bioassays
aids = pcp.get_assays(
    name='blood-brain barrier',
    format='json'
)

# Download activity data
for aid in aids:
    activities = pcp.get_assay(aid, format='json')
    # Extract compound CIDs, SMILES, and activity values
```

### 2.3 Therapeutic Target Database (TTD)

**CNS Drugs:**
- Contains: ~500 CNS-active drugs (by definition, BBB+)
- **Action:** Extract CNS drug category, assign BBB+ class

---

## Tier 3: Validated QSAR Predictions

### 3.1 High-Confidence Predictions

**Strategy:** Use our ML model to predict BBB for ChEMBL compounds, but only keep high-confidence predictions

```python
# Script: generate_validated_qsar_predictions.py
from z07_data_access.bbb_prediction_service import get_bbb_prediction_service
from chembl_webresource_client.new_client import new_client

service = get_bbb_prediction_service()

# Get all ChEMBL drugs (approved, clinical trial)
molecule = new_client.molecule

# Filter for drug-like compounds not in our dataset
drugs = molecule.filter(
    max_phase__gte=1,  # At least Phase 1
    molecule_properties__mw_freebase__lte=600,  # Drug-like
    molecule_properties__alogp__lte=5
).only(['molecule_chembl_id', 'molecule_structures'])

for drug in drugs:
    if drug['molecule_chembl_id'] not in existing_chembl_ids:
        smiles = drug['molecule_structures']['canonical_smiles']

        # Predict with chemical similarity
        pred = service.predict_from_smiles(smiles, k_neighbors=10)

        # Only keep high-confidence predictions
        if pred.confidence > 0.8 and pred.prediction_method == 'chemical_similarity':
            # Add to dataset with data_source = 'QSAR_validated'
            new_compounds.append({
                'chembl_id': drug['molecule_chembl_id'],
                'smiles': smiles,
                'log_bb': pred.predicted_log_bb,
                'bbb_class': pred.predicted_bbb_class,
                'data_source': f'QSAR_validated (confidence={pred.confidence:.2f})',
                'method': 'chemical_similarity'
            })
```

### 3.2 Cross-Validation Filter

**Strategy:** Only add QSAR predictions that agree across multiple methods

```python
# Use multiple QSAR models and only keep consensus predictions
models = [
    our_ml_model,
    simple_qsar_rules,
    external_webservice_predictor
]

consensus_threshold = 0.8  # 80% of models must agree on BBB class

for compound in candidates:
    predictions = [model.predict(compound.smiles) for model in models]

    # Check consensus
    bbb_classes = [p.bbb_class for p in predictions]
    consensus = max(set(bbb_classes), key=bbb_classes.count)
    agreement = bbb_classes.count(consensus) / len(bbb_classes)

    if agreement >= consensus_threshold:
        # Add to dataset
        pass
```

---

## Implementation Plan

### Phase 1: Quick Wins (1-2 days)

**Target:** +500 compounds (literature-validated)

1. **Download B3DB database**
   ```bash
   wget https://www.docking.org/b3db/b3db.sdf.gz
   python parse_b3db.py
   ```

2. **Download BBBP dataset (MoleculeNet)**
   ```python
   from deepchem.molnet import load_bbbp
   bbbp_tasks, bbbp_datasets, transformers = load_bbbp()
   ```

3. **Extract DrugBank CNS drugs**
   ```python
   # Parse drugbank.xml
   # Filter for category="Central Nervous System Agents"
   # Extract brain/plasma ratio data
   ```

**Expected Output:**
- `data/bbb/b3db_compounds.csv` (+1,500 compounds)
- `data/bbb/bbbp_dataset.csv` (+2,050 compounds)
- `data/bbb/drugbank_cns.csv` (+200 compounds)

### Phase 2: Literature Mining (3-5 days)

**Target:** +300 compounds (experimental)

1. **PubMed automated search**
   ```python
   python scripts/mine_pubmed_bbb_data.py \
       --query "blood-brain barrier log BB" \
       --max-results 1000 \
       --output data/bbb/pubmed_bbb_candidates.json
   ```

2. **Manual curation**
   - Review top 100 papers with BBB data tables
   - Extract compound names, SMILES, Log BB values
   - Record DOI for provenance

3. **Data validation**
   - Check SMILES validity
   - Remove duplicates
   - Verify Log BB values are in reasonable range (-5 to +2)

**Expected Output:**
- `data/bbb/literature_bbb_data.csv` (+300 compounds with DOIs)

### Phase 3: Database Integration (2-3 days)

**Target:** +2,000 compounds

1. **ChEMBL assay mining**
   ```python
   python scripts/expand_chembl_bbb.py \
       --assay-types "Brain penetration,CNS penetration,Kp brain" \
       --output data/bbb/chembl_expanded.csv
   ```

2. **PubChem BioAssay**
   ```python
   python scripts/fetch_pubchem_bbb_assays.py \
       --aids "1851,2551,2789" \
       --output data/bbb/pubchem_bbb.csv
   ```

3. **Merge and deduplicate**
   ```python
   python scripts/merge_bbb_datasets.py \
       --input-dir data/bbb/ \
       --output data/bbb/bbb_dataset_expanded_v2.csv
   ```

**Expected Output:**
- `data/bbb/bbb_dataset_expanded_v2.csv` (~10,000 compounds)

### Phase 4: Validation & Quality Control (1 day)

**Quality Checks:**

1. **Remove duplicates** (by SMILES canonical form)
2. **Validate SMILES** (RDKit parsing)
3. **Check Log BB range** (-5.0 to +2.0)
4. **Verify BBB class consistency** (Log BB vs class)
5. **Check molecular weight** (<1000 Da for drug-like)
6. **Remove outliers** (statistical analysis)

```python
# Script: validate_expanded_dataset.py
import pandas as pd
from rdkit import Chem
from scipy import stats

def validate_bbb_dataset(df):
    # 1. Remove duplicates
    df = df.drop_duplicates(subset=['smiles'])

    # 2. Validate SMILES
    df = df[df['smiles'].apply(lambda x: Chem.MolFromSmiles(x) is not None)]

    # 3. Check Log BB range
    df = df[(df['log_bb'] >= -5.0) & (df['log_bb'] <= 2.0)]

    # 4. Verify BBB class consistency
    def check_consistency(row):
        if row['log_bb'] > -1.0 and row['bbb_class'] != 'BBB+':
            return False
        if row['log_bb'] < -2.0 and row['bbb_class'] != 'BBB-':
            return False
        return True

    df = df[df.apply(check_consistency, axis=1)]

    # 5. Check molecular weight
    df = df[df['mol_weight'] < 1000]

    # 6. Remove outliers (3 sigma rule)
    z_scores = stats.zscore(df['log_bb'])
    df = df[abs(z_scores) < 3]

    return df
```

---

## Data Sources Summary

| Source | Type | Expected Compounds | Quality | Effort |
|--------|------|-------------------|---------|--------|
| B3DB | Database | +1,500 | High | Low |
| BBBP (MoleculeNet) | Dataset | +2,050 | High | Low |
| DrugBank CNS | Database | +200 | High | Medium |
| PubMed Literature | Papers | +300 | Very High | High |
| ChEMBL Assays | Database | +500 | Medium | Medium |
| PubChem BioAssay | Database | +500 | Medium | Low |
| Validated QSAR | Computed | +1,000 | Medium | Low |
| **TOTAL** | - | **+6,050** | - | - |

**Final Dataset Size:** 6,497 + 6,050 = **12,547 compounds**

---

## Code Structure

```
zones/z07_data_access/scripts/dataset_expansion/
├── 01_download_databases.py        # B3DB, BBBP, DrugBank
├── 02_mine_pubmed.py               # PubMed literature mining
├── 03_expand_chembl.py             # ChEMBL assay mining
├── 04_fetch_pubchem.py             # PubChem BioAssay
├── 05_generate_qsar_predictions.py # High-confidence QSAR
├── 06_merge_datasets.py            # Combine all sources
├── 07_validate_dataset.py          # Quality control
├── 08_retrain_model.py             # Retrain ML model on expanded data
└── README.md                       # Usage instructions
```

---

## Quality Metrics (Post-Expansion)

**Target Metrics:**
- **Total Compounds:** 10,000+
- **Literature-Validated:** 500+ (vs 36 current)
- **Experimental Data:** 4,000+ (vs 36 current)
- **QSAR Predictions:** 6,000+ (high-confidence only)
- **Duplicate Rate:** <1%
- **Invalid SMILES:** 0%
- **Log BB Range Violations:** 0%
- **Class Consistency:** 100%

**Model Performance (After Retraining):**
- **Target MAE:** <0.5 (vs 1.4 current)
- **Target Accuracy:** >75% (vs 41.5% current)
- **Target R²:** >0.7 (vs -0.067 current)

---

## Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1: Quick Wins | 1-2 days | +3,750 compounds (databases) |
| Phase 2: Literature Mining | 3-5 days | +300 compounds (papers) |
| Phase 3: Database Integration | 2-3 days | +2,000 compounds (assays) |
| Phase 4: Validation & QC | 1 day | Final dataset (10,000+) |
| Phase 5: Model Retraining | 1 day | Improved ML model |
| **TOTAL** | **8-12 days** | **12,500+ compounds** |

---

## Priority Recommendations

### Immediate Actions (High ROI, Low Effort):

1. **Download B3DB** - 1,500 high-quality compounds in 1 hour
2. **Download BBBP dataset** - 2,050 compounds in 30 minutes
3. **Extract DrugBank CNS drugs** - 200 compounds in 2 hours

**Total:** +3,750 compounds in ~4 hours

### Next Steps (Medium Effort):

4. **Mine ChEMBL assays** - 500 compounds in 1 day
5. **Fetch PubChem BioAssays** - 500 compounds in 4 hours

**Total:** +1,000 compounds in ~2 days

### Advanced (High Effort, High Quality):

6. **PubMed literature mining** - 300 experimental compounds in 3-5 days
7. **Generate validated QSAR predictions** - 1,000 compounds in 1 day

**Total:** +1,300 compounds in 4-6 days

---

## Expected Impact

### Before Expansion:
- **Compounds:** 6,497
- **Experimental:** 36 (0.5%)
- **ML Model MAE:** 1.4
- **ML Model Accuracy:** 41.5%

### After Expansion:
- **Compounds:** 12,500+
- **Experimental:** 4,000+ (32%)
- **ML Model MAE:** <0.5 (est.)
- **ML Model Accuracy:** >75% (est.)

**Improvement:**
- **+92% more compounds**
- **+111x more experimental data**
- **~3x better MAE**
- **~1.8x better accuracy**

---

## Next Steps

To execute this plan:

1. **Create dataset_expansion/ directory:**
   ```bash
   mkdir -p zones/z07_data_access/scripts/dataset_expansion
   ```

2. **Start with Phase 1 (Quick Wins):**
   ```bash
   python zones/z07_data_access/scripts/dataset_expansion/01_download_databases.py
   ```

3. **Validate results:**
   ```bash
   python zones/z07_data_access/scripts/dataset_expansion/07_validate_dataset.py
   ```

4. **Retrain ML model:**
   ```bash
   python zones/z05_models/train_bbb_qsar.py --data expanded_dataset.csv
   ```

Would you like me to implement any of these phases? I recommend starting with **Phase 1 (Quick Wins)** - we can get 3,750 high-quality compounds in just a few hours.
