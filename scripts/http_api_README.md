# HTTP API Service Bus

Modern FastAPI service bus for post-rewrite architecture.

## Features

- **Component Registry Integration**: Search and query component registry
- **Database Access**: Execute read-only SQL queries
- **Zone Discovery**: List available zones
- **MCP Server Integration**: View configured MCP servers
- **Health Checks**: Monitor service and dependency status
- **CORS Support**: Configure allowed origins
- **Graceful Degradation**: Works even if dependencies unavailable

## Quick Start

### Install Dependencies

```bash
pip install fastapi uvicorn python-dotenv asyncpg pydantic
```

### Run the Service

```bash
# Default (port 8000)
python3.11 scripts/http_api.py

# Custom port
HTTP_API_PORT=8001 python3.11 scripts/http_api.py

# Custom host and port
HTTP_API_HOST=127.0.0.1 HTTP_API_PORT=8001 python3.11 scripts/http_api.py
```

### Using uvicorn directly

```bash
uvicorn scripts.http_api:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### Health & Status

- `GET /` - Service health check
- `GET /health` - Detailed health with dependency status

### Component Registry

- `POST /api/components/search` - Search components
  ```json
  {
    "query": "neo4j",
    "component_type": "service",
    "zone": "z07_data_access",
    "limit": 20
  }
  ```
- `GET /api/components/{component_id}` - Get component details
- `GET /api/components/stats` - Registry statistics

### Database

- `GET /api/db/query?sql=SELECT...&limit=100` - Execute read-only query

### Zone Services

- `GET /api/zones` - List all available zones

### MCP Integration

- `GET /api/mcp/servers` - List configured MCP servers

## Configuration

Set via environment variables:

- `HTTP_API_HOST` - Bind host (default: 0.0.0.0)
- `HTTP_API_PORT` - Bind port (default: 8000)
- `ALLOWED_ORIGINS` - CORS origins (comma-separated, default: localhost:3000,8080,5173)
- `POSTGRES_HOST` - PostgreSQL host (default: localhost)
- `POSTGRES_PORT` - PostgreSQL port (default: 5435)
- `POSTGRES_USER` - PostgreSQL user (default: postgres)
- `POSTGRES_PASSWORD` - PostgreSQL password

## Architecture

The service bus uses:
- **FastAPI**: Modern async web framework
- **Component Registry**: ResilientComponentRegistry with 3-tier fallback
- **Database Pool**: asyncpg connection pool
- **Zone Discovery**: File system scanning

## Testing

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test component search
curl -X POST http://localhost:8000/api/components/search \
  -H "Content-Type: application/json" \
  -d '{"query": "database", "limit": 5}'

# Test zones list
curl http://localhost:8000/api/zones

# Test MCP servers list
curl http://localhost:8000/api/mcp/servers
```

## Development

### Interactive API Docs

Visit http://localhost:8000/docs for Swagger UI documentation.

### Add New Endpoints

1. Define Pydantic models
2. Create endpoint function with `@app.get()` or `@app.post()`
3. Add error handling with HTTPException
4. Test with curl or Swagger UI

## Deployment

### Docker

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python3.11", "scripts/http_api.py"]
```

### Production

Use a production ASGI server:

```bash
gunicorn scripts.http_api:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## Troubleshooting

### Port Already in Use

Change the port:
```bash
HTTP_API_PORT=8001 python3.11 scripts/http_api.py
```

### Component Registry Not Available

Service will work in degraded mode. Check:
1. `.outcomes/migrations/component_registry_resilient.py` exists
2. PostgreSQL running on port 5435
3. Check logs for initialization errors

### Database Not Available

Service will work without database endpoints. Check:
1. PostgreSQL running
2. Connection credentials correct
3. `db_connection_pool.py` in z07_data_access zone

## Version History

- **2.0.0** (2025-12-19): Post-rewrite architecture with zone integration
- **1.0.0** (Pre-Nov 8): Original implementation (archived)
