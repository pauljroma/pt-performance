"""
Intent Classifier for Sapphire v3.17 (Enhanced)

Purpose: Auto-detect query intent to optimize pathway routing
Author: Sapphire World-Class Swarm Agent 8 + Agent 2 Pattern Enhancement
Date: 2025-12-03
Zone: z07_data_access
Version: 3.17 (Enhanced with BBB/ADME/Clinical patterns)

Classification Categories:
- similarity: Find entities similar to X
- rescue: Find rescue compounds for gene/disease
- mechanism: Understand drug mechanism or pathway
- pathway: Pathway enrichment or analysis
- cross_entity: Cross-entity relationships (gene-drug, drug-disease)
- literature: Literature search or evidence gathering
- interaction: Drug interactions or combinations
- validation: Target validation or biomarker discovery
- bbb_safety: Blood-brain barrier penetration and CNS access
- adme: ADME properties (pharmacokinetics, toxicity, metabolism)
- clinical: Clinical trials, FDA approval, drug phases
- complex: Multi-step query requiring orchestration
"""

import re
from typing import Dict, List, Tuple
from dataclasses import dataclass
from enum import Enum


class QueryIntent(Enum):
    """Query intent categories"""
    SIMILARITY = "similarity"
    RESCUE = "rescue"
    MECHANISM = "mechanism"
    PATHWAY = "pathway"
    CROSS_ENTITY = "cross_entity"
    LITERATURE = "literature"
    INTERACTION = "interaction"
    VALIDATION = "validation"
    BBB_SAFETY = "bbb_safety"
    ADME = "adme"
    CLINICAL = "clinical"
    COMPLEX = "complex"
    UNKNOWN = "unknown"


class QueryComplexity(Enum):
    """Query complexity levels"""
    SIMPLE = "simple"        # Direct Run (<100ms)
    MEDIUM = "medium"        # Atomic Fusion (200-500ms)
    COMPLEX = "complex"      # Unified Orchestration (400-2000ms)
    VERY_COMPLEX = "very_complex"  # Full metagraph intelligence


@dataclass
class IntentClassification:
    """Intent classification result"""
    primary_intent: QueryIntent
    secondary_intents: List[QueryIntent]
    complexity: QueryComplexity
    confidence: float  # 0-1
    recommended_pathway: str  # direct_run, atomic_fusion, unified_orchestration
    entity_type: str  # gene, drug, pathway, disease, unknown
    keywords_matched: List[str]
    reasoning: str


class IntentClassifier:
    """
    Rule-based intent classifier for Sapphire queries

    Uses keyword matching and pattern recognition to classify
    user queries into intent categories and recommend optimal
    execution pathways.
    """

    def __init__(self):
        # Intent keyword patterns (case-insensitive)
        self.intent_patterns = {
            QueryIntent.SIMILARITY: [
                r'\b(similar|like|resembl|analog|analogous|related|comparable)\b',
                r'\b(find .* similar to)\b',
                r'\b(what.*similar)\b',
                r'\b(genes? like|drugs? like)\b',
                r'\b(analog(ous)?|analog(y|ies))\b',
            ],
            QueryIntent.RESCUE: [
                r'\b(rescue|compensate|suppress|ameliorat)\b',
                r'\b(treat|therapeutic|therapy)\b',
                r'\b(rescue .* for|rescues)\b',
                r'\b(what rescues|find rescue)\b',
            ],
            QueryIntent.MECHANISM: [
                r'\b(mechanism|how .* work|mode of action|MOA)\b',
                r'\b(targets?|binding|interact with)\b',
                r'\b(pathway.*involv|process.*involv)\b',
                r'\b(explain .* mechanism)\b',
            ],
            QueryIntent.PATHWAY: [
                r'\b(pathway|enrichment|network)\b',
                r'\b(pathway analysis|pathway.*enrich)\b',
                r'\b(biological process|cellular process)\b',
                r'\b(what pathways|which pathways)\b',
                r'\b(enrich(ed|ment)|pathway.*enrich)\b',
                r'\b(gene set.*enrichment|enrichment.*analysis)\b',
                r'\b(KEGG|Reactome|WikiPathways)\b',
            ],
            QueryIntent.CROSS_ENTITY: [
                r'\b(gene.*drug|drug.*gene)\b',
                r'\b(gene.*disease|disease.*gene)\b',
                r'\b(drug.*disease|disease.*drug)\b',
                r'\b(relationship between)\b',
                r'\b(connect(ed)?|link(ed)?|association)\b',
                r'\b(how .* (and|with) .* connected)\b',
                r'\b(between .* and)\b',
            ],
            QueryIntent.LITERATURE: [
                r'\b(papers?|publications?|literature|studies?)\b',
                r'\b(evidence|research|findings?)\b',
                r'\b(what does .* say|according to)\b',
                r'\b(search .* literature|find papers)\b',
            ],
            QueryIntent.INTERACTION: [
                r'\b(interaction|synerg(y|istic|ies)|combin|together)\b',
                r'\b(drug.*drug|drug combinations?)\b',
                r'\b(side effect|adverse|contraindic)\b',
                r'\b(drug interactions?|check interactions?)\b',
                r'\b(synergistic effects?|synergy)\b',
                r'\b(combined (with|treatment))\b',
            ],
            QueryIntent.VALIDATION: [
                r'\b(validat(e|ion)|confirm|verify|check)\b',
                r'\b(biomarker|target validation)\b',
                r'\b(is .* (target|associated|biomarker))\b',
                r'\b(are .* targets?)\b',
                r'\b(evidence for|support for)\b',
                r'\b(validate .* (as|for))\b',
            ],
            QueryIntent.BBB_SAFETY: [
                r'\b(BBB|blood.?brain.?barrier)\b',
                r'\b(CNS (penetration|access|entry))\b',
                r'\b(brain penetra(tion|nt))\b',
                r'\b(cross(es)? .* (BBB|blood.?brain|brain))\b',
                r'\b(BBB.?(permeable|permeability))\b',
                r'\b(neuro.?penetra(tion|nt))\b',
                r'\b(central nervous system access)\b',
            ],
            QueryIntent.ADME: [
                r'\b(ADME|pharmacokinetic|PK)\b',
                r'\b(absorption|distribution|metabolism|excretion)\b',
                r'\b(toxicity|toxic|safety profile)\b',
                r'\b(clearance|half.?life|t1/2)\b',
                r'\b(bioavailability|metaboli[sz])\b',
                r'\b(liver metabolism|renal clearance)\b',
                r'\b(drug.?metaboli[sz]ing|CYP450)\b',
                r'\b(pharmaco(kinetics|dynamics))\b',
            ],
            QueryIntent.CLINICAL: [
                r'\b(clinical trials?|trials? phase)\b',
                r'\b(FDA (approved|approval))\b',
                r'\b(phase (I|II|III|1|2|3))\b',
                r'\b(efficacy|effectiveness)\b',
                r'\b(approved for|indication)\b',
                r'\b(clinical (data|evidence|study))\b',
                r'\b(patient (outcomes?|response))\b',
                r'\b(regulatory (approval|status))\b',
                r'\b(are there (clinical )?trials?)\b',
            ],
        }

        # Entity type patterns (enhanced)
        self.entity_patterns = {
            'gene': [
                r'\b[A-Z][A-Z0-9]{2,6}\b',  # Gene symbols (SCN1A, BRCA1, etc.)
                r'\b[A-Z]{3,}[0-9]+[A-Z]?\b',  # Gene variants (SCN1A, BRCA1, TSC2)
                r'\b[A-Z]{2,}[0-9]+/[0-9]+\b',  # Gene families (BRCA1/2, SCN1A/B)
                r'\bgenes?\b',
                r'\b(oncogene|tumor suppressor|kinase)\b',
            ],
            'drug': [
                r'\b[A-Z][a-z]{5,}[a-z]\b',  # Drug names (Gabapentin, Fenfluramine)
                r'\b(Gabapentin|Fenfluramine|Stiripentol|Valproate|Carbamazepine)\b',
                r'\b(Oxcarbazepine|Lamotrigine|Topiramate|Levetiracetam)\b',
                r'\b(Memantine|Donepezil|Rivastigmine|Galantamine)\b',
                r'\bCHEMBL[0-9]+\b',  # CHEMBL IDs
                r'\bdrugs?\b',
                r'\bcompounds?\b',
                r'\bmedicat(ion|e)s?\b',
            ],
            'pathway': [
                r'\bpathway\b',
                r'\bsignal(ing|ling)\b',
                r'\b(KEGG|Reactome|WikiPathways)\b',
                r'\b(mTOR|MAPK|PI3K|Wnt|Notch)\b',  # Common pathway names
            ],
            'disease': [
                r'\b(syndrome|disease|disorder|cancer)\b',
                r'\b(Dravet|Lennox-Gastaut|West)\b',  # Epilepsy syndromes
                r'\b(epilepsy|seizures?)\b',
                r'\b(Alzheimer|Parkinson|Huntington)\b',  # Neurodegenerative
                r'\b(autism|ASD|ADHD)\b',
                r'\b(breast cancer|lung cancer|melanoma)\b',
            ],
        }

        # Complexity indicators (enhanced)
        self.complexity_indicators = {
            'simple': [
                r'^find .* similar to \w+$',
                r'^what.*similar to \w+\??$',
                r'^\w+ similar$',
                r'^does .* cross',  # "Does X cross the BBB?"
                r'^is .* (approved|BBB|toxic)',  # "Is X FDA approved?"
            ],
            'medium': [
                r'\bcompare\b',
                r'\b(vs|versus|compared to)\b',
                r'\bmultiple\b',
                r'\b\w+-related\b',  # "X-related genes"
                r'\b(properties|profile) of\b',  # "ADME properties of X"
                r'\b(assess|evaluate|analyze)\b',
            ],
            'complex': [
                r'\band\b.*\band\b',  # Multiple conditions (X and Y and Z)
                r'\bvia\b',
                r'\bthrough\b',
                r'\bmulti-step\b',
                r'\benrichment.*for.*-related\b',  # "enrichment for X-related genes"
                r'\b(find|identify).*for.*-related\b',
                r'\b(that|which) .* and .* and\b',  # "drugs that X and Y and Z"
            ],
            'very_complex': [
                r'\b(discover|identify|find all)\b.*\b(that|which)\b',
                r'\b(optimize|best|optimal)\b',
                r'\b(across|multiple|all)\b.*\b(spaces?|embeddings?)\b',
                r'\bhow many\b',  # Aggregate queries
                r'\bcount\b',
                r'\bstatistics?\b',
            ],
        }

    def classify(self, query: str) -> IntentClassification:
        """
        Classify query intent and recommend execution pathway

        Args:
            query: User query string

        Returns:
            IntentClassification with intent, complexity, and pathway recommendation
        """
        query_lower = query.lower()

        # Step 1: Identify primary and secondary intents
        intent_scores = {}
        matched_keywords = {}

        for intent, patterns in self.intent_patterns.items():
            score = 0
            keywords = []
            for pattern in patterns:
                matches = re.findall(pattern, query_lower, re.IGNORECASE)
                if matches:
                    score += len(matches)
                    keywords.extend(matches)

            if score > 0:
                intent_scores[intent] = score
                matched_keywords[intent] = keywords

        # Determine primary intent
        if intent_scores:
            primary_intent = max(intent_scores.items(), key=lambda x: x[1])[0]
            secondary_intents = [
                intent for intent, score in intent_scores.items()
                if intent != primary_intent and score > 0
            ]
            confidence = min(intent_scores[primary_intent] / 3.0, 1.0)
            primary_keywords = matched_keywords[primary_intent]
        else:
            primary_intent = QueryIntent.UNKNOWN
            secondary_intents = []
            confidence = 0.0
            primary_keywords = []

        # Step 2: Detect entity type
        entity_type = self._detect_entity_type(query)

        # Step 3: Assess complexity
        complexity = self._assess_complexity(query, len(secondary_intents))

        # Step 4: Recommend pathway
        pathway = self._recommend_pathway(
            primary_intent,
            complexity,
            len(secondary_intents)
        )

        # Step 5: Generate reasoning
        reasoning = self._generate_reasoning(
            primary_intent,
            secondary_intents,
            complexity,
            pathway,
            entity_type
        )

        return IntentClassification(
            primary_intent=primary_intent,
            secondary_intents=secondary_intents,
            complexity=complexity,
            confidence=confidence,
            recommended_pathway=pathway,
            entity_type=entity_type,
            keywords_matched=primary_keywords,
            reasoning=reasoning
        )

    def _detect_entity_type(self, query: str) -> str:
        """Detect primary entity type in query"""
        entity_scores = {}

        for entity_type, patterns in self.entity_patterns.items():
            score = 0
            for pattern in patterns:
                if re.search(pattern, query, re.IGNORECASE):
                    score += 1
            if score > 0:
                entity_scores[entity_type] = score

        if entity_scores:
            return max(entity_scores.items(), key=lambda x: x[1])[0]
        return 'unknown'

    def _assess_complexity(self, query: str, num_intents: int) -> QueryComplexity:
        """Assess query complexity based on patterns and multiple intents"""
        query_lower = query.lower()

        # Check very complex indicators first
        for pattern in self.complexity_indicators['very_complex']:
            if re.search(pattern, query_lower):
                return QueryComplexity.VERY_COMPLEX

        # Check complex indicators
        for pattern in self.complexity_indicators['complex']:
            if re.search(pattern, query_lower):
                return QueryComplexity.COMPLEX

        # Multiple intents suggest medium complexity
        if num_intents >= 2:
            return QueryComplexity.MEDIUM

        # Check medium indicators
        for pattern in self.complexity_indicators['medium']:
            if re.search(pattern, query_lower):
                return QueryComplexity.MEDIUM

        # Check simple indicators
        for pattern in self.complexity_indicators['simple']:
            if re.search(pattern, query_lower):
                return QueryComplexity.SIMPLE

        # Default based on query length
        word_count = len(query.split())
        if word_count <= 5:
            return QueryComplexity.SIMPLE
        elif word_count <= 10:
            return QueryComplexity.MEDIUM
        else:
            return QueryComplexity.COMPLEX

    def _recommend_pathway(
        self,
        intent: QueryIntent,
        complexity: QueryComplexity,
        num_secondary_intents: int
    ) -> str:
        """Recommend execution pathway based on intent and complexity"""

        # Very complex or unknown -> Unified Orchestration
        if complexity == QueryComplexity.VERY_COMPLEX or intent == QueryIntent.UNKNOWN:
            return "unified_orchestration"

        # Complex or multiple intents -> Unified Orchestration
        if complexity == QueryComplexity.COMPLEX or num_secondary_intents >= 2:
            return "unified_orchestration"

        # Medium complexity or comparing perspectives -> Atomic Fusion
        if complexity == QueryComplexity.MEDIUM:
            return "atomic_fusion"

        # Simple similarity queries -> Direct Run
        if intent == QueryIntent.SIMILARITY and complexity == QueryComplexity.SIMPLE:
            return "direct_run"

        # Default for simple queries -> Direct Run
        if complexity == QueryComplexity.SIMPLE:
            return "direct_run"

        # Default -> Atomic Fusion (safe middle ground)
        return "atomic_fusion"

    def _generate_reasoning(
        self,
        primary: QueryIntent,
        secondary: List[QueryIntent],
        complexity: QueryComplexity,
        pathway: str,
        entity_type: str
    ) -> str:
        """Generate human-readable reasoning for classification"""

        reasoning_parts = []

        # Intent reasoning
        if primary != QueryIntent.UNKNOWN:
            reasoning_parts.append(
                f"Primary intent is {primary.value} query"
            )
            if secondary:
                secondary_str = ", ".join([s.value for s in secondary])
                reasoning_parts.append(
                    f"with secondary intents: {secondary_str}"
                )
        else:
            reasoning_parts.append("Intent unclear")

        # Entity reasoning
        if entity_type != 'unknown':
            reasoning_parts.append(f"targeting {entity_type} entities")

        # Complexity reasoning
        reasoning_parts.append(f"Complexity: {complexity.value}")

        # Pathway reasoning
        pathway_reasoning = {
            "direct_run": "Simple query suitable for direct execution with gold embeddings",
            "atomic_fusion": "Medium complexity requiring user-controlled source selection",
            "unified_orchestration": "Complex query requiring full metagraph intelligence and multi-step execution"
        }
        reasoning_parts.append(
            f"Recommended pathway: {pathway} - {pathway_reasoning[pathway]}"
        )

        return ". ".join(reasoning_parts) + "."


# Convenience function
def classify_intent(query: str) -> IntentClassification:
    """Classify query intent (convenience function)"""
    classifier = IntentClassifier()
    return classifier.classify(query)


# Tool definition for Claude integration
TOOL_DEFINITION = {
    "name": "classify_intent",
    "description": """
    Classify user query intent to optimize execution pathway (v3.17 Enhanced).

    Use this to:
    - Determine query complexity (simple, medium, complex, very_complex)
    - Identify primary intent (similarity, rescue, mechanism, pathway, cross_entity,
      literature, interaction, validation, bbb_safety, adme, clinical, complex)
    - Get pathway recommendation (direct_run, atomic_fusion, unified_orchestration)
    - Detect entity types (gene, drug, pathway, disease)

    NEW Intent Categories (v3.17):
    - bbb_safety: Blood-brain barrier penetration, CNS access, brain penetration
    - adme: ADME properties, pharmacokinetics, toxicity, metabolism, clearance
    - clinical: Clinical trials, FDA approval, drug phases, efficacy

    Returns:
    - primary_intent: Main query intent
    - secondary_intents: Additional detected intents
    - complexity: Query complexity level
    - confidence: Classification confidence (0-1)
    - recommended_pathway: Suggested execution pathway
    - entity_type: Detected entity type
    - keywords_matched: Matched keywords
    - reasoning: Human-readable explanation
    """,
    "input_schema": {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "User query to classify"
            }
        },
        "required": ["query"]
    }
}


async def execute(params: Dict) -> Dict:
    """
    Execute intent classification

    Args:
        params: {"query": str}

    Returns:
        Classification result with intent, complexity, pathway
    """
    query = params.get("query", "")

    if not query:
        return {
            "success": False,
            "error": "Query parameter is required"
        }

    try:
        classification = classify_intent(query)

        return {
            "success": True,
            "classification": {
                "primary_intent": classification.primary_intent.value,
                "secondary_intents": [
                    s.value for s in classification.secondary_intents
                ],
                "complexity": classification.complexity.value,
                "confidence": round(classification.confidence, 2),
                "recommended_pathway": classification.recommended_pathway,
                "entity_type": classification.entity_type,
                "keywords_matched": classification.keywords_matched,
                "reasoning": classification.reasoning
            },
            "query": query
        }

    except Exception as e:
        return {
            "success": False,
            "error": f"Classification failed: {str(e)}",
            "query": query
        }
