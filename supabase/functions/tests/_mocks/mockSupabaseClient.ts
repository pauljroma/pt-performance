// ============================================================================
// Mock Supabase Client for Testing
// Health Intelligence Platform - Edge Function Tests
// ============================================================================

export interface MockQueryBuilder {
  select: (columns?: string) => MockQueryBuilder;
  insert: (data: any) => MockQueryBuilder;
  update: (data: any) => MockQueryBuilder;
  delete: () => MockQueryBuilder;
  eq: (column: string, value: any) => MockQueryBuilder;
  neq: (column: string, value: any) => MockQueryBuilder;
  gt: (column: string, value: any) => MockQueryBuilder;
  gte: (column: string, value: any) => MockQueryBuilder;
  lt: (column: string, value: any) => MockQueryBuilder;
  lte: (column: string, value: any) => MockQueryBuilder;
  in: (column: string, values: any[]) => MockQueryBuilder;
  not: (column: string, operator: string, value: any) => MockQueryBuilder;
  order: (column: string, options?: { ascending?: boolean }) => MockQueryBuilder;
  limit: (count: number) => MockQueryBuilder;
  single: () => Promise<{ data: any; error: any }>;
  maybeSingle: () => Promise<{ data: any; error: any }>;
  then: (resolve: (value: { data: any; error: any }) => void) => Promise<{ data: any; error: any }>;
}

export interface MockSupabaseClient {
  from: (table: string) => MockQueryBuilder;
  _mockData: Record<string, any[]>;
  _mockErrors: Record<string, any>;
  setMockData: (table: string, data: any[]) => void;
  setMockError: (table: string, error: any) => void;
  clearMocks: () => void;
}

export function createMockSupabaseClient(): MockSupabaseClient {
  const mockData: Record<string, any[]> = {};
  const mockErrors: Record<string, any> = {};
  let currentTable = '';
  let queryFilters: Array<{ column: string; operator: string; value: any }> = [];
  let selectedColumns = '*';
  let orderColumn = '';
  let orderAscending = true;
  let limitCount = 0;
  let insertData: any = null;

  const resetQuery = () => {
    queryFilters = [];
    selectedColumns = '*';
    orderColumn = '';
    orderAscending = true;
    limitCount = 0;
    insertData = null;
  };

  const applyFilters = (data: any[]): any[] => {
    let result = [...data];

    for (const filter of queryFilters) {
      result = result.filter((row) => {
        const value = row[filter.column];
        switch (filter.operator) {
          case 'eq':
            return value === filter.value;
          case 'neq':
            return value !== filter.value;
          case 'gt':
            return value > filter.value;
          case 'gte':
            return value >= filter.value;
          case 'lt':
            return value < filter.value;
          case 'lte':
            return value <= filter.value;
          case 'in':
            return filter.value.includes(value);
          case 'not_is_null':
            return value !== null;
          default:
            return true;
        }
      });
    }

    if (orderColumn) {
      result.sort((a, b) => {
        const aVal = a[orderColumn];
        const bVal = b[orderColumn];
        if (aVal < bVal) return orderAscending ? -1 : 1;
        if (aVal > bVal) return orderAscending ? 1 : -1;
        return 0;
      });
    }

    if (limitCount > 0) {
      result = result.slice(0, limitCount);
    }

    return result;
  };

  const queryBuilder: MockQueryBuilder = {
    select: (columns?: string) => {
      selectedColumns = columns || '*';
      return queryBuilder;
    },
    insert: (data: any) => {
      insertData = data;
      return queryBuilder;
    },
    update: (_data: any) => {
      return queryBuilder;
    },
    delete: () => {
      return queryBuilder;
    },
    eq: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'eq', value });
      return queryBuilder;
    },
    neq: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'neq', value });
      return queryBuilder;
    },
    gt: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'gt', value });
      return queryBuilder;
    },
    gte: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'gte', value });
      return queryBuilder;
    },
    lt: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'lt', value });
      return queryBuilder;
    },
    lte: (column: string, value: any) => {
      queryFilters.push({ column, operator: 'lte', value });
      return queryBuilder;
    },
    in: (column: string, values: any[]) => {
      queryFilters.push({ column, operator: 'in', value: values });
      return queryBuilder;
    },
    not: (column: string, operator: string, _value: any) => {
      if (operator === 'is') {
        queryFilters.push({ column, operator: 'not_is_null', value: null });
      }
      return queryBuilder;
    },
    order: (column: string, options?: { ascending?: boolean }) => {
      orderColumn = column;
      orderAscending = options?.ascending ?? true;
      return queryBuilder;
    },
    limit: (count: number) => {
      limitCount = count;
      return queryBuilder;
    },
    single: async () => {
      if (mockErrors[currentTable]) {
        const result = { data: null, error: mockErrors[currentTable] };
        resetQuery();
        return result;
      }

      if (insertData) {
        const newData = {
          id: crypto.randomUUID(),
          ...insertData,
          created_at: new Date().toISOString()
        };
        if (!mockData[currentTable]) {
          mockData[currentTable] = [];
        }
        mockData[currentTable].push(newData);
        const result = { data: newData, error: null };
        resetQuery();
        return result;
      }

      const data = mockData[currentTable] || [];
      const filtered = applyFilters(data);
      const result = { data: filtered[0] || null, error: filtered[0] ? null : { message: 'Not found' } };
      resetQuery();
      return result;
    },
    maybeSingle: async () => {
      if (mockErrors[currentTable]) {
        const result = { data: null, error: mockErrors[currentTable] };
        resetQuery();
        return result;
      }

      const data = mockData[currentTable] || [];
      const filtered = applyFilters(data);
      const result = { data: filtered[0] || null, error: null };
      resetQuery();
      return result;
    },
    then: async (resolve) => {
      if (mockErrors[currentTable]) {
        const result = { data: null, error: mockErrors[currentTable] };
        resetQuery();
        resolve(result);
        return result;
      }

      if (insertData) {
        const newData = {
          id: crypto.randomUUID(),
          ...insertData,
          created_at: new Date().toISOString()
        };
        if (!mockData[currentTable]) {
          mockData[currentTable] = [];
        }
        mockData[currentTable].push(newData);
        const result = { data: newData, error: null };
        resetQuery();
        resolve(result);
        return result;
      }

      const data = mockData[currentTable] || [];
      const filtered = applyFilters(data);
      const result = { data: filtered, error: null };
      resetQuery();
      resolve(result);
      return result;
    },
  };

  return {
    from: (table: string) => {
      currentTable = table;
      resetQuery();
      return queryBuilder;
    },
    _mockData: mockData,
    _mockErrors: mockErrors,
    setMockData: (table: string, data: any[]) => {
      mockData[table] = data;
    },
    setMockError: (table: string, error: any) => {
      mockErrors[table] = error;
    },
    clearMocks: () => {
      for (const key in mockData) {
        delete mockData[key];
      }
      for (const key in mockErrors) {
        delete mockErrors[key];
      }
    },
  };
}

// Re-export for convenience
export const mockSupabaseClient = createMockSupabaseClient();
