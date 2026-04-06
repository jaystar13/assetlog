import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    // 에러 로깅
    if (exception instanceof HttpException) {
      const res = exception.getResponse();
      console.error(`[${exception.getStatus()}]`, typeof res === 'string' ? res : JSON.stringify(res));
    } else {
      console.error('Unhandled exception:', exception);
    }

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    response.status(status).json({
      statusCode: status,
      message:
        typeof message === 'string'
          ? message
          : (message as Record<string, unknown>).message || message,
      timestamp: new Date().toISOString(),
    });
  }
}
