export class AppError extends Error {
  constructor({ code, statusCode = 500, message, details }) {
    super(message || code || 'internal_server_error');
    this.name = 'AppError';
    this.code = code || 'internal_server_error';
    this.statusCode = statusCode;
    this.details = details;
  }
}

export function createAppError(code, statusCode, message, details) {
  return new AppError({ code, statusCode, message, details });
}

export function normalizeError(error) {
  if (error instanceof AppError) return error;

  const isProduction = process.env.NODE_ENV === 'production';

  return new AppError({
    code: 'internal_server_error',
    statusCode: 500,
    message: isProduction ? 'Unexpected server error' : (error?.message || 'Unexpected server error'),
  });
}

export function sendApiError(res, errorOrConfig) {
  const appError = errorOrConfig instanceof Error
    ? normalizeError(errorOrConfig)
    : new AppError(errorOrConfig);

  const payload = {
    error: appError.code,
    message: appError.message,
  };

  if (appError.details !== undefined) {
    payload.details = appError.details;
  }

  return res.status(appError.statusCode).json(payload);
}

export function globalErrorMiddleware(err, req, res, next) {
  const appError = normalizeError(err);
  return sendApiError(res, appError);
}
