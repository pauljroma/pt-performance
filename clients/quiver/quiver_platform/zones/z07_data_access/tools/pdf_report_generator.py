#!/usr/bin/env python3
"""
PDF Report Generator - Sapphire Atomic Tool

Converts Sapphire HTML reports to PDF using best available method.
Integrates with Sapphire's tool ecosystem for automated report delivery.

Component ID: sapphire-pdf-generator-v1.0
Reusability Score: 95% (any HTML → PDF in reporting context)
Category: Reporting & Documentation
"""

import os
import subprocess
import logging
from pathlib import Path
from typing import Dict, Any, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


TOOL_DEFINITION = {
    "name": "pdf_report_generator",
    "description": """Generate PDF version of Sapphire scientist reports.

**Use Cases:**
- Convert HTML scientist reports to PDF for sharing
- Create printable versions of drug discovery reports
- Generate PDF documentation from HTML templates

**Supported Reports:**
- Scientist reports (epilepsy, als, parkinsons, alzheimers, pain, glp1, tsc2)
- Custom HTML reports (provide HTML path)

**Methods** (auto-detected):
1. Playwright (best quality - headless Chromium)
2. wkhtmltopdf (good quality - lightweight CLI)
3. WeasyPrint (Python-based)
4. Manual (provides browser instructions)

**Output:**
Returns PDF file path and metadata (size, conversion method, generation time).""",

    "input_schema": {
        "type": "object",
        "properties": {
            "report_type": {
                "type": "string",
                "description": "Type of report: 'scientist' for disease reports, 'custom' for custom HTML",
                "enum": ["scientist", "custom"],
                "default": "scientist"
            },
            "disease": {
                "type": "string",
                "description": "Disease key for scientist reports (e.g., 'tsc2', 'epilepsy', 'als'). Required if report_type='scientist'.",
            },
            "html_path": {
                "type": "string",
                "description": "Path to custom HTML file. Required if report_type='custom'."
            },
            "output_path": {
                "type": "string",
                "description": "Custom PDF output path (optional). Auto-generated if not provided."
            },
            "page_size": {
                "type": "string",
                "description": "PDF page size",
                "enum": ["A4", "Letter", "Legal"],
                "default": "A4"
            },
            "margin": {
                "type": "string",
                "description": "Page margins (e.g., '20mm', '1in')",
                "default": "20mm"
            }
        },
        "required": []
    }
}


class PDFGenerator:
    """PDF generation engine with multiple conversion methods"""

    def __init__(self):
        self.method = self._detect_method()

    def _detect_method(self) -> str:
        """Detect best available PDF conversion method"""
        # Try Playwright
        try:
            import playwright
            return "playwright"
        except ImportError:
            pass

        # Try wkhtmltopdf
        try:
            result = subprocess.run(['which', 'wkhtmltopdf'],
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return "wkhtmltopdf"
        except:
            pass

        # Try WeasyPrint
        try:
            from weasyprint import HTML
            return "weasyprint"
        except:
            pass

        return "manual"

    async def convert(self, html_path: Path, pdf_path: Path,
                page_size: str = "A4", margin: str = "20mm") -> Dict[str, Any]:
        """
        Convert HTML to PDF

        Returns:
            Dict with conversion results
        """
        import time
        start_time = time.time()

        if not html_path.exists():
            return {
                "success": False,
                "error": f"HTML file not found: {html_path}",
                "method": self.method
            }

        pdf_path.parent.mkdir(parents=True, exist_ok=True)

        # Attempt conversion
        success = False
        error_msg = None

        if self.method == "playwright":
            success, error_msg = await self._convert_playwright(
                html_path, pdf_path, page_size, margin
            )
        elif self.method == "wkhtmltopdf":
            success, error_msg = self._convert_wkhtmltopdf(
                html_path, pdf_path, page_size, margin
            )
        elif self.method == "weasyprint":
            success, error_msg = self._convert_weasyprint(html_path, pdf_path)
        else:
            error_msg = self._manual_instructions(html_path, pdf_path)

        generation_time = (time.time() - start_time) * 1000  # ms

        if success:
            file_size = pdf_path.stat().st_size
            return {
                "success": True,
                "pdf_path": str(pdf_path),
                "html_path": str(html_path),
                "file_size_kb": round(file_size / 1024, 2),
                "method": self.method,
                "generation_time_ms": round(generation_time, 2),
                "created_at": datetime.now().isoformat()
            }
        else:
            return {
                "success": False,
                "error": error_msg,
                "method": self.method,
                "html_path": str(html_path),
                "manual_instructions": error_msg if self.method == "manual" else None
            }

    async def _convert_playwright(self, html_path, pdf_path, page_size, margin):
        """Playwright conversion (async)"""
        try:
            from playwright.async_api import async_playwright

            async with async_playwright() as p:
                browser = await p.chromium.launch()
                page = await browser.new_page()
                await page.goto(f"file://{html_path.absolute()}")
                await page.pdf(
                    path=str(pdf_path),
                    format=page_size,
                    margin={'top': margin, 'right': margin,
                           'bottom': margin, 'left': margin},
                    print_background=True
                )
                await browser.close()
            return True, None
        except Exception as e:
            return False, f"Playwright error: {str(e)}"

    def _convert_wkhtmltopdf(self, html_path, pdf_path, page_size, margin):
        """wkhtmltopdf conversion"""
        try:
            cmd = [
                'wkhtmltopdf',
                '--page-size', page_size,
                '--margin-top', margin,
                '--margin-right', margin,
                '--margin-bottom', margin,
                '--margin-left', margin,
                '--enable-local-file-access',
                str(html_path),
                str(pdf_path)
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                return True, None
            else:
                return False, f"wkhtmltopdf error: {result.stderr}"
        except Exception as e:
            return False, f"wkhtmltopdf error: {str(e)}"

    def _convert_weasyprint(self, html_path, pdf_path):
        """WeasyPrint conversion"""
        try:
            from weasyprint import HTML
            HTML(filename=str(html_path)).write_pdf(str(pdf_path))
            return True, None
        except Exception as e:
            return False, f"WeasyPrint error: {str(e)}"

    def _manual_instructions(self, html_path, pdf_path):
        """Generate manual conversion instructions"""
        http_url = None
        if "sapphire_reporting/outputs/scientist" in str(html_path):
            filename = html_path.name
            http_url = f"http://100.84.49.12:8082/scientist/{filename}"

        instructions = [
            "No automated PDF converter available.",
            f"HTML Report: {html_path}",
        ]
        if http_url:
            instructions.append(f"View at: {http_url}")

        instructions.extend([
            f"Save PDF to: {pdf_path}",
            "",
            "Manual Steps:",
            "1. Open HTML in browser",
            "2. Press Cmd+P (Mac) or Ctrl+P (Windows)",
            "3. Select 'Save as PDF'",
            f"4. Save to: {pdf_path}",
            "",
            "Or install converter:",
            "  brew install wkhtmltopdf",
            "  # OR",
            "  pip install playwright && playwright install chromium"
        ])

        return "\n".join(instructions)


async def execute(tool_input: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute PDF report generation

    Args:
        tool_input: Dictionary with:
            - report_type: 'scientist' or 'custom'
            - disease: Disease key (for scientist reports)
            - html_path: Custom HTML path (for custom reports)
            - output_path: Optional custom output path
            - page_size: PDF page size (default: A4)
            - margin: Page margins (default: 20mm)

    Returns:
        Dictionary with PDF generation results
    """
    report_type = tool_input.get("report_type", "scientist")
    page_size = tool_input.get("page_size", "A4")
    margin = tool_input.get("margin", "20mm")

    base_dir = Path("/Users/expo/Code/expo/clients/quiver/quiver_platform/zones/z01_presentation/sapphire_reporting/outputs")

    # Determine HTML and PDF paths
    if report_type == "scientist":
        disease = tool_input.get("disease")
        if not disease:
            return {
                "success": False,
                "error": "Missing required parameter: disease (for scientist reports)"
            }

        html_path = base_dir / "scientist" / f"{disease}.html"
        pdf_path = base_dir / "pdf" / f"{disease}.pdf"

    elif report_type == "custom":
        html_path_str = tool_input.get("html_path")
        if not html_path_str:
            return {
                "success": False,
                "error": "Missing required parameter: html_path (for custom reports)"
            }

        html_path = Path(html_path_str)
        pdf_path = Path(tool_input.get("output_path", html_path.with_suffix('.pdf')))

    else:
        return {
            "success": False,
            "error": f"Invalid report_type: {report_type}. Use 'scientist' or 'custom'."
        }

    # Custom output path override
    if tool_input.get("output_path") and report_type == "scientist":
        pdf_path = Path(tool_input["output_path"])

    # Generate PDF
    generator = PDFGenerator()
    result = await generator.convert(html_path, pdf_path, page_size, margin)

    return result


# Singleton instance for reuse
_pdf_generator = None


def get_pdf_generator():
    """Get singleton PDF generator instance"""
    global _pdf_generator
    if _pdf_generator is None:
        _pdf_generator = PDFGenerator()
    return _pdf_generator
