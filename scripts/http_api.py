#!/usr/bin/env python3.11
"""
HTTP API Service Bus - Post-Rewrite Architecture
Provides HTTP endpoints for zone services, component registry, and MCP integration.

Author: claude-code-agent
Date: 2025-12-19
Version: 2.0 (Post-Rewrite)
"""

import asyncio
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

# Add project root to path for imports
REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

# Load environment
load_dotenv(override=False)

# Optional: Import component registry
try:
    sys.path.insert(0, str(REPO_ROOT / ".outcomes" / "migrations"))
    from component_registry_resilient import ResilientComponentRegistry
    HAS_COMPONENT_REGISTRY = True
except ImportError as e:
    print(f"⚠️  Component Registry not available: {e}")
    HAS_COMPONENT_REGISTRY = False

# Optional: Import PostgreSQL connection
try:
    sys.path.insert(0, str(REPO_ROOT / "clients" / "quiver" / "quiver_platform" / "zones" / "z07_data_access"))
    from db_connection_pool import get_pool
    HAS_DB_POOL = True
except ImportError as e:
    print(f"⚠️  Database pool not available: {e}")
    HAS_DB_POOL = False

# ============================================================================
# FastAPI Application
# ============================================================================

app = FastAPI(
    title="HTTP API Service Bus",
    version="2.0.0",
    description="Service bus for post-rewrite zone architecture"
)

# CORS configuration
ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "http://localhost:3000,http://localhost:8080,http://localhost:5173"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# Global State
# ============================================================================

component_registry: Optional[ResilientComponentRegistry] = None
db_pool = None

# ============================================================================
# Pydantic Models
# ============================================================================

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    services: Dict[str, bool]
    version: str

class ComponentSearchRequest(BaseModel):
    query: Optional[str] = None
    component_type: Optional[str] = None
    zone: Optional[str] = None
    limit: int = 20

class ComponentResponse(BaseModel):
    component_id: str
    component_name: str
    component_type: str
    zone: str
    description: Optional[str] = None
    file_path: Optional[str] = None

# ============================================================================
# Startup/Shutdown
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    global component_registry, db_pool
    
    print("🚀 Starting HTTP API Service Bus...")
    
    # Initialize Component Registry
    if HAS_COMPONENT_REGISTRY:
        try:
            component_registry = ResilientComponentRegistry()
            await component_registry.initialize()
            print("✅ Component Registry initialized")
        except Exception as e:
            print(f"⚠️  Component Registry initialization failed: {e}")
            component_registry = None
    
    # Initialize Database Pool
    if HAS_DB_POOL:
        try:
            db_pool = await get_pool()
            print("✅ Database pool initialized")
        except Exception as e:
            print(f"⚠️  Database pool initialization failed: {e}")
            db_pool = None
    
    print("✅ HTTP API Service Bus ready")

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up on shutdown."""
    global component_registry, db_pool
    
    print("🛑 Shutting down HTTP API Service Bus...")
    
    if component_registry:
        await component_registry.close()
    
    if db_pool:
        await db_pool.close()
    
    print("✅ Shutdown complete")

# ============================================================================
# Health & Status Endpoints
# ============================================================================

@app.get("/", response_model=HealthResponse)
async def root():
    """Root endpoint - service health check."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {
            "component_registry": component_registry is not None,
            "database": db_pool is not None,
        },
        "version": "2.0.0"
    }

@app.get("/health", response_model=HealthResponse)
async def health():
    """Detailed health check."""
    services = {
        "component_registry": False,
        "database": False,
    }
    
    # Check component registry
    if component_registry:
        try:
            # Quick check if registry is accessible
            services["component_registry"] = component_registry.mode is not None
        except Exception:
            pass
    
    # Check database
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            services["database"] = True
        except Exception:
            pass
    
    status = "healthy" if any(services.values()) else "degraded"
    
    return {
        "status": status,
        "timestamp": datetime.utcnow().isoformat(),
        "services": services,
        "version": "2.0.0"
    }

# ============================================================================
# Component Registry Endpoints
# ============================================================================

@app.post("/api/components/search", response_model=List[ComponentResponse])
async def search_components(request: ComponentSearchRequest):
    """Search component registry."""
    if not component_registry:
        raise HTTPException(status_code=503, detail="Component registry not available")
    
    try:
        results = await component_registry.search(
            query=request.query,
            component_type=request.component_type,
            zone=request.zone,
            limit=request.limit
        )
        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Search failed: {str(e)}")

@app.get("/api/components/{component_id}", response_model=ComponentResponse)
async def get_component(component_id: str):
    """Get component details by ID."""
    if not component_registry:
        raise HTTPException(status_code=503, detail="Component registry not available")
    
    try:
        result = await component_registry.get(component_id)
        if not result:
            raise HTTPException(status_code=404, detail="Component not found")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lookup failed: {str(e)}")

@app.get("/api/components/stats")
async def get_registry_stats():
    """Get component registry statistics."""
    if not component_registry:
        raise HTTPException(status_code=503, detail="Component registry not available")
    
    try:
        stats = await component_registry.get_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stats failed: {str(e)}")

# ============================================================================
# Database Endpoints (Example)
# ============================================================================

@app.get("/api/db/query")
async def execute_query(
    sql: str = Query(..., description="SQL query to execute"),
    limit: int = Query(100, description="Maximum rows to return")
):
    """Execute a read-only SQL query."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")
    
    # Security: Only allow SELECT queries
    if not sql.strip().upper().startswith("SELECT"):
        raise HTTPException(status_code=400, detail="Only SELECT queries allowed")
    
    try:
        async with db_pool.acquire() as conn:
            results = await conn.fetch(sql)
            # Convert to list of dicts
            return [dict(row) for row in results[:limit]]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Query failed: {str(e)}")

# ============================================================================
# Zone Service Endpoints (Extensible)
# ============================================================================

@app.get("/api/zones")
async def list_zones():
    """List all available zones."""
    zones_dir = REPO_ROOT / "clients" / "quiver" / "quiver_platform" / "zones"
    
    if not zones_dir.exists():
        return {"zones": []}
    
    zones = []
    for item in zones_dir.iterdir():
        if item.is_dir() and item.name.startswith("z"):
            zones.append({
                "name": item.name,
                "path": str(item.relative_to(REPO_ROOT))
            })
    
    return {"zones": sorted(zones, key=lambda x: x["name"])}

# ============================================================================
# MCP Integration Endpoints
# ============================================================================

@app.get("/api/mcp/servers")
async def list_mcp_servers():
    """List configured MCP servers."""
    mcp_config_path = REPO_ROOT / ".vscode" / "mcp.json"
    
    if not mcp_config_path.exists():
        return {"servers": []}
    
    try:
        import json
        with open(mcp_config_path) as f:
            config = json.load(f)
        
        servers = []
        for name, server_config in config.get("servers", {}).items():
            servers.append({
                "name": name,
                "command": server_config.get("command"),
                "args": server_config.get("args", [])
            })
        
        return {"servers": servers}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read MCP config: {str(e)}")

# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    
    host = os.getenv("HTTP_API_HOST", "0.0.0.0")
    port = int(os.getenv("HTTP_API_PORT", "8000"))
    
    print(f"Starting HTTP API Service Bus on {host}:{port}")
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )
