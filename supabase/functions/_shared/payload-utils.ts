// Payload Optimization Utilities for Edge Functions
// ACP-940 - Minimize API response sizes
//
// Provides:
// - Paginated response wrappers
// - Field selection (sparse fieldsets)
// - Gzip compression for clients that accept it
// - Standard response headers (CORS, cache-control, content-type)
// - Query parameter parsing for page, pageSize, fields, sort, order

import { corsHeaders } from './errors.ts';

// ============================================================================
// Types
// ============================================================================

export interface PaginationMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasMore: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: PaginationMeta;
}

export interface QueryParams {
  page: number;
  pageSize: number;
  fields: string[];
  sort: string;
  order: 'asc' | 'desc';
}

// ============================================================================
// Pagination
// ============================================================================

const MAX_PAGE_SIZE = 100;
const DEFAULT_PAGE_SIZE = 20;

/**
 * Wraps an array of data in a standard paginated response envelope.
 *
 * @param data    - The slice of results for the current page
 * @param page    - Current page number (1-based)
 * @param pageSize - Number of items per page
 * @param total   - Total number of matching records (before pagination)
 * @returns A PaginatedResponse object with data and pagination metadata
 *
 * @example
 * ```ts
 * const result = paginatedResponse(rows, 1, 20, 57);
 * // { data: [...], pagination: { page: 1, pageSize: 20, total: 57, totalPages: 3, hasMore: true } }
 * ```
 */
export function paginatedResponse<T>(
  data: T[],
  page: number,
  pageSize: number,
  total: number,
): PaginatedResponse<T> {
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  return {
    data,
    pagination: {
      page,
      pageSize,
      total,
      totalPages,
      hasMore: page < totalPages,
    },
  };
}

// ============================================================================
// Field Selection
// ============================================================================

/**
 * Returns a new object containing only the requested fields from the source.
 * Supports nested field access via dot notation (e.g. "profile.name").
 * Fields that don't exist on the source object are silently skipped.
 *
 * @param obj    - The source object to pick fields from
 * @param fields - Array of field names to include
 * @returns A new object with only the requested fields
 *
 * @example
 * ```ts
 * const patient = { id: '1', first_name: 'John', last_name: 'Doe', email: 'j@d.com', ssn: '***' };
 * selectFields(patient, ['id', 'first_name', 'last_name']);
 * // { id: '1', first_name: 'John', last_name: 'Doe' }
 * ```
 */
export function selectFields<T extends Record<string, unknown>>(
  obj: T,
  fields: string[],
): Partial<T> {
  if (!fields.length) return obj;

  const result: Record<string, unknown> = {};

  for (const field of fields) {
    // Support dot notation for nested fields (e.g. "profile.name")
    if (field.includes('.')) {
      const parts = field.split('.');
      let current: unknown = obj;
      let target: Record<string, unknown> = result;

      for (let i = 0; i < parts.length; i++) {
        const part = parts[i]!;
        if (i === parts.length - 1) {
          // Last part — assign the value
          if (
            current !== null &&
            current !== undefined &&
            typeof current === 'object' &&
            part in (current as Record<string, unknown>)
          ) {
            target[part] = (current as Record<string, unknown>)[part];
          }
        } else {
          // Intermediate part — traverse
          if (
            current !== null &&
            current !== undefined &&
            typeof current === 'object' &&
            part in (current as Record<string, unknown>)
          ) {
            if (!(part in target) || typeof target[part] !== 'object') {
              target[part] = {};
            }
            current = (current as Record<string, unknown>)[part];
            target = target[part] as Record<string, unknown>;
          } else {
            break;
          }
        }
      }
    } else if (field in obj) {
      result[field] = obj[field];
    }
  }

  return result as Partial<T>;
}

/**
 * Applies field selection to every item in an array.
 *
 * @param items  - Array of objects
 * @param fields - Array of field names to include
 * @returns Array of objects with only the requested fields
 */
export function selectFieldsArray<T extends Record<string, unknown>>(
  items: T[],
  fields: string[],
): Partial<T>[] {
  if (!fields.length) return items;
  return items.map((item) => selectFields(item, fields));
}

// ============================================================================
// Compression
// ============================================================================

/**
 * Compresses a response body with gzip if the client accepts it.
 * Falls back to uncompressed body if compression is not supported
 * or the CompressionStream API is unavailable.
 *
 * @param body           - The string body to compress (typically JSON)
 * @param acceptEncoding - The Accept-Encoding header value from the request
 * @returns An object with the (possibly compressed) body and content-encoding header value
 *
 * @example
 * ```ts
 * const { body, contentEncoding } = await compressResponse(jsonStr, req.headers.get('accept-encoding') ?? '');
 * const headers = { 'Content-Encoding': contentEncoding };
 * return new Response(body, { headers });
 * ```
 */
export async function compressResponse(
  body: string,
  acceptEncoding: string,
): Promise<{ body: Uint8Array | string; contentEncoding: string }> {
  const supportsGzip = acceptEncoding.includes('gzip');

  if (supportsGzip && typeof CompressionStream !== 'undefined') {
    try {
      const encoder = new TextEncoder();
      const inputBytes = encoder.encode(body);

      const cs = new CompressionStream('gzip');
      const writer = cs.writable.getWriter();
      writer.write(inputBytes);
      writer.close();

      const compressedResponse = new Response(cs.readable);
      const compressedBuffer = await compressedResponse.arrayBuffer();
      return {
        body: new Uint8Array(compressedBuffer),
        contentEncoding: 'gzip',
      };
    } catch (err) {
      console.warn('Gzip compression failed, sending uncompressed:', err);
      return { body, contentEncoding: 'identity' };
    }
  }

  return { body, contentEncoding: 'identity' };
}

// ============================================================================
// Standard Headers
// ============================================================================

/**
 * Returns a standard set of response headers for optimized API responses.
 * Includes CORS, content-type, and cache-control headers.
 *
 * @param options - Optional overrides
 * @param options.contentEncoding - Content-Encoding value (e.g. "gzip")
 * @param options.maxAge          - Cache-Control max-age in seconds (default: 0, no cache)
 * @param options.contentType     - Content-Type value (default: "application/json")
 * @returns A headers object suitable for the Response constructor
 */
export function standardHeaders(options?: {
  contentEncoding?: string;
  maxAge?: number;
  contentType?: string;
}): Record<string, string> {
  const headers: Record<string, string> = {
    ...corsHeaders,
    'Content-Type': options?.contentType ?? 'application/json; charset=utf-8',
    'Cache-Control': options?.maxAge
      ? `public, max-age=${options.maxAge}, s-maxage=${options.maxAge}`
      : 'no-cache, no-store, must-revalidate',
    'Vary': 'Accept-Encoding',
  };

  if (options?.contentEncoding && options.contentEncoding !== 'identity') {
    headers['Content-Encoding'] = options.contentEncoding;
  }

  return headers;
}

// ============================================================================
// Query Parameter Parsing
// ============================================================================

/**
 * Extracts pagination, field selection, and sorting parameters from a URL.
 * Provides safe defaults and clamps values to prevent abuse.
 *
 * Supported query params:
 * - page      (default: 1, min: 1)
 * - pageSize  (default: 20, min: 1, max: 100)
 * - fields    (comma-separated list of field names)
 * - sort      (field name to sort by, default: "created_at")
 * - order     (asc|desc, default: "desc")
 *
 * @param url - The full request URL string or URL object
 * @returns Parsed and validated query parameters
 *
 * @example
 * ```ts
 * const params = parseQueryParams('https://example.com/api?page=2&pageSize=10&fields=id,name&sort=name&order=asc');
 * // { page: 2, pageSize: 10, fields: ['id', 'name'], sort: 'name', order: 'asc' }
 * ```
 */
export function parseQueryParams(url: string | URL): QueryParams {
  const parsedUrl = typeof url === 'string' ? new URL(url) : url;
  const searchParams = parsedUrl.searchParams;

  // Page: integer >= 1
  const rawPage = parseInt(searchParams.get('page') ?? '1', 10);
  const page = Number.isNaN(rawPage) || rawPage < 1 ? 1 : rawPage;

  // Page size: integer between 1 and MAX_PAGE_SIZE
  const rawPageSize = parseInt(searchParams.get('pageSize') ?? String(DEFAULT_PAGE_SIZE), 10);
  const pageSize = Number.isNaN(rawPageSize)
    ? DEFAULT_PAGE_SIZE
    : Math.min(Math.max(rawPageSize, 1), MAX_PAGE_SIZE);

  // Fields: comma-separated, trimmed, non-empty, sanitized
  const rawFields = searchParams.get('fields') ?? '';
  const fields = rawFields
    .split(',')
    .map((f) => f.trim())
    .filter((f) => f.length > 0)
    .filter((f) => /^[a-zA-Z_][a-zA-Z0-9_.]*$/.test(f)); // Only allow safe field names

  // Sort field: sanitized identifier
  const rawSort = searchParams.get('sort') ?? 'created_at';
  const sort = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(rawSort) ? rawSort : 'created_at';

  // Order: asc or desc only
  const rawOrder = searchParams.get('order')?.toLowerCase();
  const order: 'asc' | 'desc' = rawOrder === 'asc' ? 'asc' : 'desc';

  return { page, pageSize, fields, sort, order };
}

// ============================================================================
// Convenience: Build a complete optimized response
// ============================================================================

/**
 * One-shot helper that applies field selection, wraps in pagination,
 * optionally compresses, and returns a ready-to-send Response.
 *
 * @param items          - Full page of data rows from the database
 * @param total          - Total matching records (for pagination metadata)
 * @param params         - Parsed query parameters (from parseQueryParams)
 * @param acceptEncoding - Accept-Encoding header from the client request
 * @param cacheMaxAge    - Optional cache-control max-age in seconds
 * @returns A fully constructed Response object
 */
export async function buildOptimizedResponse<T extends Record<string, unknown>>(
  items: T[],
  total: number,
  params: QueryParams,
  acceptEncoding: string,
  cacheMaxAge?: number,
): Promise<Response> {
  // Apply field selection
  const projected = params.fields.length > 0
    ? selectFieldsArray(items, params.fields)
    : items;

  // Build paginated envelope
  const payload = paginatedResponse(projected, params.page, params.pageSize, total);

  // Serialize
  const jsonBody = JSON.stringify(payload);

  // Compress if client supports it
  const { body, contentEncoding } = await compressResponse(jsonBody, acceptEncoding);

  // Build headers
  const headers = standardHeaders({
    contentEncoding,
    maxAge: cacheMaxAge,
  });

  return new Response(body, {
    status: 200,
    headers,
  });
}
