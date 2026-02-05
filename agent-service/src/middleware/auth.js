import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';
import { createAppError } from '../errors/api-error.js';

const authClient = createClient(
  config.supabase.url,
  config.supabase.anonKey || config.supabase.serviceKey,
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

function getAuthorizedTherapistIds(user) {
  const candidateIds = [
    user?.id,
    user?.app_metadata?.therapist_id,
    user?.user_metadata?.therapist_id,
  ];

  return new Set(candidateIds.filter(Boolean));
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
    req.authorizedTherapistIds = getAuthorizedTherapistIds(data.user);
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

export { parseBearerToken, getAuthorizedTherapistIds };
