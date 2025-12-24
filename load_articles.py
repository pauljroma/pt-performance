#!/usr/bin/env python3
"""Load articles into Supabase flexible content system"""
import os
import re
import json
from pathlib import Path
from supabase import create_client
import yaml

# Load .env
env_path = Path('.env')
if env_path.exists():
    for line in env_path.read_text().splitlines():
        if '=' in line and not line.startswith('#'):
            key, val = line.split('=', 1)
            os.environ[key.strip()] = val.strip()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')
ARTICLES_DIR = Path('docs/help-articles/baseball')

print("="*70)
print("📚 Loading Articles into Flexible Content System")
print("="*70)
print(f"\n🔗 Supabase: {SUPABASE_URL}")
print(f"📂 Articles: {ARTICLES_DIR}")

# Connect
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get article content type ID
print("\n📝 Getting content type ID for 'article'...")
ct_result = supabase.table('content_types').select('id').eq('type_key', 'article').execute()
if not ct_result.data:
    print("❌ Content type 'article' not found!")
    exit(1)

content_type_id = ct_result.data[0]['id']
print(f"✅ Content type ID: {content_type_id}")

# Helper functions
def parse_frontmatter(content):
    pattern = r'^---\s*\n(.*?)\n---\s*\n(.*)$'
    match = re.match(pattern, content, re.DOTALL)
    if match:
        return yaml.safe_load(match.group(1)), match.group(2)
    return {}, content

def extract_references(content):
    pattern = r'## References\s*\n(.*?)(?=\n##|\Z)'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return []
    refs = re.findall(r'^\d+\.\s+(.+)$', match.group(1), re.MULTILINE)
    return [{'citation': ref, 'order': i+1} for i, ref in enumerate(refs)]

def create_excerpt(content):
    clean = re.sub(r'#+ ', '', content)
    clean = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', clean)
    clean = re.sub(r'[*_]{1,2}([^*_]+)[*_]{1,2}', r'\1', clean)
    clean = re.sub(r'\n+', ' ', clean)
    if len(clean) > 150:
        clean = clean[:150].rsplit(' ', 1)[0] + '...'
    return clean.strip()

def slugify(text):
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text)
    return text.strip('-')

# Load articles
print(f"\n📂 Scanning articles...")
articles = []

for category_dir in ARTICLES_DIR.iterdir():
    if not category_dir.is_dir():
        continue

    for article_file in category_dir.glob('*.md'):
        if article_file.name.startswith('README'):
            continue

        content = article_file.read_text(encoding='utf-8')
        frontmatter, markdown = parse_frontmatter(content)

        title = frontmatter.get('title', article_file.stem.replace('-', ' ').title())
        slug = frontmatter.get('id', slugify(title))

        article_content = {
            'markdown': content,
            'reading_time': str(frontmatter.get('reading_time', '5 min')).replace(' min', ''),
            'references': extract_references(content)
        }

        metadata = {
            'author': frontmatter.get('author', 'PT Performance Medical Team'),
            'reviewed_by': frontmatter.get('reviewed_by', 'Sports Medicine Specialist'),
            'evidence_level': 'high',
            'last_reviewed': frontmatter.get('last_updated', '2025-12-20')
        }

        articles.append({
            'content_type_id': content_type_id,
            'slug': slug,
            'title': title,
            'category': frontmatter.get('category', category_dir.name),
            'subcategory': frontmatter.get('subcategory'),
            'content': article_content,
            'metadata': metadata,
            'excerpt': create_excerpt(markdown),
            'tags': frontmatter.get('tags', []),
            'difficulty': frontmatter.get('difficulty', 'intermediate'),
            'estimated_duration_minutes': int(article_content['reading_time']) if str(article_content['reading_time']).isdigit() else 5,
            'is_published': True,
            'author': metadata['author'],
            'reviewed_by': metadata['reviewed_by']
        })

print(f"✅ Found {len(articles)} articles")

# Show breakdown
from collections import Counter
categories = Counter(a['category'] for a in articles)
print("\n📊 Breakdown:")
for cat, count in sorted(categories.items()):
    print(f"   {cat}: {count} articles")

# Insert
print(f"\n🚀 Inserting {len(articles)} articles...")
inserted = 0
errors = 0

for article in articles:
    try:
        result = supabase.table('content_items').insert(article).execute()
        if result.data:
            print(f"   ✅ {article['title']}")
            inserted += 1
        else:
            print(f"   ⚠️  {article['title']} - no data returned")
            errors += 1
    except Exception as e:
        print(f"   ❌ {article['title']}: {e}")
        errors += 1

print("\n" + "="*70)
print(f"✅ Inserted: {inserted}")
print(f"❌ Errors: {errors}")
print("="*70)

if inserted > 0:
    print("\n🎉 Articles are live!")
    print(f"\nTest search:")
    print(f"  SELECT * FROM search_content('pitching velocity', 'article');")
