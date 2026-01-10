# Export Patient Data - HIPAA-Compliant Data Export API

## Overview

This Edge Function provides a HIPAA-compliant API for patients to export their complete health data, fulfilling the **Right to Access** requirement under HIPAA.

## Features

- **Multiple Export Formats**: JSON, CSV (PDF planned)
- **Granular Control**: Choose which data categories to include
- **Date Range Filtering**: Export data within specific time periods
- **Access Control**: Patients can only export their own data
- **Audit Logging**: All exports are automatically logged
- **HIPAA Compliance**: Meets data portability requirements

## Usage

### Request

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/export-patient-data' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_id": "uuid-here",
    "export_format": "json",
    "include_sessions": true,
    "include_exercises": true,
    "include_notes": true,
    "include_readiness": true,
    "include_analytics": true,
    "date_range_start": "2024-01-01",
    "date_range_end": "2024-12-31"
  }'
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `patient_id` | UUID | Yes | - | Patient ID to export data for |
| `export_format` | String | No | `"json"` | Format: `"json"`, `"csv"`, or `"pdf"` |
| `include_sessions` | Boolean | No | `true` | Include training sessions |
| `include_exercises` | Boolean | No | `true` | Include exercise logs |
| `include_notes` | Boolean | No | `true` | Include session notes |
| `include_readiness` | Boolean | No | `true` | Include daily readiness scores |
| `include_analytics` | Boolean | No | `true` | Include analytics data |
| `date_range_start` | Date | No | `null` | Start date (YYYY-MM-DD) |
| `date_range_end` | Date | No | `null` | End date (YYYY-MM-DD) |

### Response

**Success (200 OK)**:
```json
{
  "export_metadata": {
    "exported_at": "2025-12-19T12:00:00Z",
    "exported_by": "user-uuid",
    "date_range_start": "2024-01-01",
    "date_range_end": "2024-12-31"
  },
  "patient": {
    "id": "patient-uuid",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "date_of_birth": "1990-01-01",
    "phone": "+1234567890",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "programs": [...],
  "sessions": [...],
  "exercise_logs": [...],
  "notes": [...],
  "daily_readiness": [...]
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or missing authentication token
- `403 Forbidden`: User doesn't have access to this patient's data
- `404 Not Found`: Patient not found
- `500 Internal Server Error`: Database or processing error

## Access Control

### Who Can Export Data?

1. **Patients**: Can export their own data
2. **Therapists**: Can export data for their assigned patients
3. **Admins**: (Future) Can export data for any patient

### Verification Process

1. Authentication via JWT token
2. Patient record lookup
3. Access verification (patient or therapist check)
4. Data export execution
5. Audit log entry creation

## Security

### Authentication

- Requires valid JWT token in `Authorization` header
- Token must be issued by Supabase Auth
- Token expiration is enforced

### Authorization

- Row-Level Security (RLS) policies enforced
- Therapists can only access their patients' data
- Patients can only access their own data

### Audit Logging

Every export request is automatically logged with:
- User ID and email
- Patient ID
- Timestamp
- Data categories exported
- Date range (if specified)
- Export format

## Export Formats

### JSON

Complete structured data in JSON format. Ideal for:
- Data portability to other systems
- Programmatic processing
- Archival purposes

### CSV

Tabular data in CSV format. Ideal for:
- Excel/Google Sheets import
- Manual data review
- Simple analytics

Each data category (programs, sessions, exercises, etc.) is exported as a separate CSV section.

### PDF

*Coming soon*

Formatted report in PDF format. Ideal for:
- Patient-friendly viewing
- Printing
- Sharing with other healthcare providers

## HIPAA Compliance

### Right to Access (45 CFR 164.524)

This API fulfills HIPAA's requirement that patients must be able to:
- Access their Protected Health Information (PHI)
- Receive copies in the format requested
- Direct PHI to a third party

### Data Portability

Exported data is in machine-readable formats (JSON, CSV) that can be:
- Imported into other systems
- Processed programmatically
- Shared with other healthcare providers

### Audit Trail

All exports are logged in the `audit_logs` table with:
- Compliance category: `PHI_ACCESS`
- Sensitivity flag: `true`
- Complete audit trail for HIPAA compliance

## Development

### Local Testing

```bash
# Serve the function locally
supabase functions serve export-patient-data --no-verify-jwt

# Test with curl
curl -X POST 'http://localhost:54321/functions/v1/export-patient-data' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"patient_id": "uuid-here"}'
```

### Deployment

```bash
# Deploy to Supabase
supabase functions deploy export-patient-data
```

## Error Handling

The function includes comprehensive error handling:
- Authentication errors (401)
- Authorization errors (403)
- Resource not found (404)
- Database errors (500)
- Invalid parameters (400)

All errors are logged and include descriptive messages.

## Future Enhancements

1. **PDF Export**: Generate formatted PDF reports
2. **Email Delivery**: Send export via email
3. **Scheduled Exports**: Automatic periodic exports
4. **Compression**: ZIP archives for large exports
5. **Encryption**: Optional password-protected exports

## Related Documentation

- [HIPAA Compliance Checklist](/docs/COMPLIANCE_HIPAA_CHECKLIST.md)
- [Audit Logging](/docs/AUDIT_LOGGING.md)
- [Security Guide](/docs/SECURITY_GUIDE.md)
- [Migration: create_audit_logs_table.sql](/supabase/migrations/20251219000002_create_audit_logs_table.sql)
- [Migration: create_data_export_api.sql](/supabase/migrations/20251219000003_create_data_export_api.sql)

## Support

For issues or questions:
- Security: security@ptperformance.com
- Technical: support@ptperformance.com
