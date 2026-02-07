# Environment Setup

## Required Environment Variables

Before running the application, you must set up environment variables:

1. Copy the template:
   ```bash
   cp .env.template .env
   ```

2. Edit `.env` and fill in secure values:
   - Use strong, random passwords (min 20 characters)
   - Never share or commit `.env` to version control

3. Generate secure passwords using:
   ```bash
   openssl rand -base64 32
   ```

## Variable Reference

| Variable | Service | Required |
|----------|---------|----------|
| POSTGRES_PASSWORD | Main PostgreSQL | Yes |
| PGVECTOR_PASSWORD | PGVector Database | Yes |
| NEO4J_USER | Neo4j Graph DB | Yes |
| NEO4J_PASSWORD | Neo4j Graph DB | Yes |
| N8N_BASIC_AUTH_PASSWORD | N8N Workflow | Yes |

## Security Notes

- All passwords should be at least 20 characters
- Use different passwords for each service
- Rotate credentials periodically
- Never log or print credentials
