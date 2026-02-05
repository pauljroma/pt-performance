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

export async function requireAuthenticatedUser(req, res, next) {
  try {
    const token = parseBearerToken(req.headers.authorization);

    if (!token) {
      return next(createAppError('authentication_required', 401, 'Missing or invalid Bearer token'));
    }

    const { data, error } = await authClient.auth.getUser(token);

    if (error || !data?.user) {
      return next(createAppError('invalid_auth_token', 401, 'Unable to verify user identity'));
    }

    req.user = data.user;
    return next();
  } catch (error) {
    return next(error);
  }
}

export function requireTherapistOwnership(req, res, next) {
  const { therapistId } = req.params;
  const userId = req.user?.id;

  if (!therapistId || !userId) {
    return next(createAppError('forbidden', 403, 'Missing therapist ownership context'));
  }

  if (therapistId !== userId) {
    return next(createAppError('forbidden', 403, 'User is not authorized to access this therapist scope'));
  }

  return next();
}

