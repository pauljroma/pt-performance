import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';
import { createAppError } from '../errors/api-error.js';

const authClient = createClient(
  config.supabase.url,
  config.supabase.anonKey || '',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

const adminClient = createClient(
  config.supabase.url,
  config.supabase.serviceKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

function parseBearerToken(headerValue) {
  if (!headerValue) return null;
  const [scheme, token] = headerValue.split(' ');

  if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) {
    return null;
  }

  return token;
}

async function fetchTherapistIdsByColumn(columnName, authUserId, client = adminClient) {
  const { data, error } = await client
    .from('therapists')
    .select('id')
    .eq(columnName, authUserId);

  if (error) {
    const missingColumn = error.message?.includes(`column therapists.${columnName} does not exist`)
      || error.message?.includes(`column \"${columnName}\" does not exist`);

    if (missingColumn) {
      return [];
    }

    throw error;
  }

  return (data || []).map((row) => row.id).filter(Boolean);
}

async function resolveTherapistIdsForUser(authUserId, client = adminClient) {
  if (!authUserId) return [];

  const [byUserId, byAuthUserId] = await Promise.all([
    fetchTherapistIdsByColumn('user_id', authUserId, client),
    fetchTherapistIdsByColumn('auth_user_id', authUserId, client),
  ]);

  return Array.from(new Set([...byUserId, ...byAuthUserId]));
}

export async function requireAuthenticatedUser(req, res, next) {
  try {
    if (!config.supabase.anonKey) {
      return next(
        createAppError(
          'auth_configuration_error',
          500,
          'SUPABASE_ANON_KEY is required for authenticated user verification'
        )
      );
    }

    const token = parseBearerToken(req.headers.authorization);

    if (!token) {
      return next(createAppError('authentication_required', 401, 'Missing or invalid Bearer token'));
    }

    const { data, error } = await authClient.auth.getUser(token);

    if (error || !data?.user) {
      return next(createAppError('invalid_auth_token', 401, 'Unable to verify user identity'));
    }

    req.user = data.user;
    req.authorizedTherapistIds = new Set(await resolveTherapistIdsForUser(data.user.id));

    if (!req.authorizedTherapistIds.size) {
      return next(createAppError('forbidden', 403, 'No therapist profile linked to this user'));
    }

    return next();
  } catch (error) {
    return next(error);
  }
}

export function requireTherapistOwnership(req, res, next) {
  const { therapistId } = req.params;
  const authorizedTherapistIds = req.authorizedTherapistIds || new Set();

  if (!therapistId || !authorizedTherapistIds.size) {
    return next(createAppError('forbidden', 403, 'Missing therapist ownership context'));
  }

  if (!authorizedTherapistIds.has(therapistId)) {
    return next(createAppError('forbidden', 403, 'User is not authorized to access this therapist scope'));
  }

  return next();
}

export { parseBearerToken, resolveTherapistIdsForUser };
