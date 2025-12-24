#!/usr/bin/env python3
"""
Article Validation Tool

Validates article structure, frontmatter, and content for linear-bootstrap.

Usage:
    python3 tools/python/validate_articles.py [PATH]
    python3 tools/python/validate_articles.py docs/help-articles/baseball/

Features:
- YAML frontmatter validation
- Required field checking
- Category validation
- Content structure validation
- Link validation
- Comprehensive error reporting
"""

import os
import sys
import re
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import yaml


# Configuration
REQUIRED_FIELDS = ["title", "category", "subcategory", "sport", "difficulty"]
OPTIONAL_FIELDS = ["video_id", "duration_minutes", "tags", "related_articles"]
VALID_DIFFICULTIES = ["beginner", "intermediate", "advanced", "expert"]
VALID_SPORTS = ["baseball", "general"]

# Valid categories by sport
VALID_CATEGORIES = {
    "baseball": [
        "hitting",
        "pitching",
        "fielding",
        "mental-performance",
        "strength-conditioning",
        "recovery",
        "injury-prevention",
        "nutrition",
        "technology",
        "youth-development",
        "advanced-training",
    ],
    "general": ["getting-started", "features", "troubleshooting", "faq"],
}


class ValidationError:
    """Represents a validation error"""

    def __init__(self, file_path: str, error_type: str, message: str, line: Optional[int] = None):
        self.file_path = file_path
        self.error_type = error_type
        self.message = message
        self.line = line

    def __str__(self):
        location = f":{self.line}" if self.line else ""
        return f"❌ {self.file_path}{location} [{self.error_type}] {self.message}"


class ArticleValidator:
    """Validates markdown articles with YAML frontmatter"""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.errors: List[ValidationError] = []
        self.warnings: List[ValidationError] = []
        self.validated_count = 0

    def validate_file(self, file_path: Path) -> bool:
        """Validate a single article file"""
        if self.verbose:
            print(f"Validating: {file_path}")

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
        except Exception as e:
            self.errors.append(
                ValidationError(str(file_path), "READ_ERROR", f"Cannot read file: {e}")
            )
            return False

        # Extract frontmatter and content
        frontmatter, body = self._extract_frontmatter(content, file_path)
        if frontmatter is None:
            return False

        # Validate frontmatter
        self._validate_frontmatter(frontmatter, file_path)

        # Validate content
        self._validate_content(body, file_path)

        self.validated_count += 1
        return len(self.errors) == 0

    def _extract_frontmatter(
        self, content: str, file_path: Path
    ) -> Tuple[Optional[Dict], str]:
        """Extract YAML frontmatter from content"""
        # Check for frontmatter delimiters
        if not content.startswith("---\n"):
            self.errors.append(
                ValidationError(
                    str(file_path),
                    "MISSING_FRONTMATTER",
                    "File must start with '---' frontmatter delimiter",
                    line=1,
                )
            )
            return None, content

        # Find closing delimiter
        match = re.match(r"^---\n(.*?)\n---\n(.*)", content, re.DOTALL)
        if not match:
            self.errors.append(
                ValidationError(
                    str(file_path),
                    "INVALID_FRONTMATTER",
                    "Frontmatter not properly closed with '---'",
                )
            )
            return None, content

        frontmatter_text = match.group(1)
        body = match.group(2)

        # Parse YAML
        try:
            frontmatter = yaml.safe_load(frontmatter_text)
        except yaml.YAMLError as e:
            self.errors.append(
                ValidationError(
                    str(file_path), "YAML_ERROR", f"Invalid YAML in frontmatter: {e}"
                )
            )
            return None, body

        return frontmatter, body

    def _validate_frontmatter(self, frontmatter: Dict, file_path: Path):
        """Validate frontmatter fields"""
        # Check required fields
        for field in REQUIRED_FIELDS:
            if field not in frontmatter:
                self.errors.append(
                    ValidationError(
                        str(file_path),
                        "MISSING_FIELD",
                        f"Required field '{field}' missing from frontmatter",
                    )
                )

        # Validate difficulty
        if "difficulty" in frontmatter:
            difficulty = frontmatter["difficulty"]
            if difficulty not in VALID_DIFFICULTIES:
                self.errors.append(
                    ValidationError(
                        str(file_path),
                        "INVALID_DIFFICULTY",
                        f"Difficulty '{difficulty}' not valid. Must be one of: {', '.join(VALID_DIFFICULTIES)}",
                    )
                )

        # Validate sport
        if "sport" in frontmatter:
            sport = frontmatter["sport"]
            if sport not in VALID_SPORTS:
                self.errors.append(
                    ValidationError(
                        str(file_path),
                        "INVALID_SPORT",
                        f"Sport '{sport}' not valid. Must be one of: {', '.join(VALID_SPORTS)}",
                    )
                )

            # Validate category for sport
            if "category" in frontmatter:
                category = frontmatter["category"]
                valid_cats = VALID_CATEGORIES.get(sport, [])
                if category not in valid_cats:
                    self.errors.append(
                        ValidationError(
                            str(file_path),
                            "INVALID_CATEGORY",
                            f"Category '{category}' not valid for sport '{sport}'. Must be one of: {', '.join(valid_cats)}",
                        )
                    )

        # Validate title not empty
        if "title" in frontmatter:
            if not frontmatter["title"] or not str(frontmatter["title"]).strip():
                self.errors.append(
                    ValidationError(
                        str(file_path), "EMPTY_TITLE", "Title field cannot be empty"
                    )
                )

        # Warn about unknown fields
        all_known_fields = REQUIRED_FIELDS + OPTIONAL_FIELDS
        for field in frontmatter.keys():
            if field not in all_known_fields:
                self.warnings.append(
                    ValidationError(
                        str(file_path),
                        "UNKNOWN_FIELD",
                        f"Unknown frontmatter field '{field}' (may be intentional)",
                    )
                )

    def _validate_content(self, body: str, file_path: Path):
        """Validate article content"""
        # Check for empty content
        if not body.strip():
            self.errors.append(
                ValidationError(
                    str(file_path), "EMPTY_CONTENT", "Article content is empty"
                )
            )
            return

        # Check for at least one heading
        if not re.search(r"^#{1,6}\s+.+", body, re.MULTILINE):
            self.warnings.append(
                ValidationError(
                    str(file_path),
                    "NO_HEADINGS",
                    "Article has no markdown headings (recommended)",
                )
            )

        # Check for minimum content length (arbitrary: 100 chars)
        if len(body.strip()) < 100:
            self.warnings.append(
                ValidationError(
                    str(file_path),
                    "SHORT_CONTENT",
                    f"Article content is very short ({len(body.strip())} chars)",
                )
            )

        # Validate internal links (basic check)
        broken_links = self._check_links(body, file_path)
        for link_text, link_target in broken_links:
            self.warnings.append(
                ValidationError(
                    str(file_path),
                    "BROKEN_LINK",
                    f"Potential broken link: [{link_text}]({link_target})",
                )
            )

    def _check_links(self, content: str, file_path: Path) -> List[Tuple[str, str]]:
        """Check for broken internal links (basic validation)"""
        broken = []
        # Find markdown links
        link_pattern = r"\[([^\]]+)\]\(([^)]+)\)"
        for match in re.finditer(link_pattern, content):
            link_text = match.group(1)
            link_target = match.group(2)

            # Only check relative links (internal)
            if not link_target.startswith(("http://", "https://", "#")):
                # Resolve relative to article location
                target_path = file_path.parent / link_target
                if not target_path.exists():
                    broken.append((link_text, link_target))

        return broken

    def validate_directory(self, directory: Path, recursive: bool = True) -> bool:
        """Validate all articles in a directory"""
        if not directory.exists():
            print(f"❌ Directory does not exist: {directory}")
            return False

        if not directory.is_dir():
            print(f"❌ Not a directory: {directory}")
            return False

        # Find all markdown files
        pattern = "**/*.md" if recursive else "*.md"
        md_files = list(directory.glob(pattern))

        # Filter out README files
        md_files = [f for f in md_files if f.name != "README.md"]

        if not md_files:
            print(f"⚠️  No markdown files found in {directory}")
            return True

        print(f"Found {len(md_files)} articles to validate\n")

        # Validate each file
        for md_file in md_files:
            self.validate_file(md_file)

        return len(self.errors) == 0

    def print_summary(self):
        """Print validation summary"""
        print("\n" + "=" * 60)
        print("VALIDATION SUMMARY")
        print("=" * 60)

        print(f"\n📊 Validated: {self.validated_count} articles")

        if self.errors:
            print(f"\n❌ Errors: {len(self.errors)}")
            for error in self.errors:
                print(f"  {error}")

        if self.warnings:
            print(f"\n⚠️  Warnings: {len(self.warnings)}")
            for warning in self.warnings:
                print(f"  {warning}")

        if not self.errors and not self.warnings:
            print("\n✅ All validations passed!")

        print("\n" + "=" * 60)


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate article structure and frontmatter"
    )
    parser.add_argument(
        "path",
        nargs="?",
        default="docs/help-articles",
        help="Path to article or directory (default: docs/help-articles)",
    )
    parser.add_argument(
        "--no-recursive", action="store_true", help="Don't validate subdirectories"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    args = parser.parse_args()

    # Get absolute path
    path = Path(args.path).resolve()

    # Create validator
    validator = ArticleValidator(verbose=args.verbose)

    # Validate
    if path.is_file():
        success = validator.validate_file(path)
    else:
        success = validator.validate_directory(path, recursive=not args.no_recursive)

    # Print summary
    validator.print_summary()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
