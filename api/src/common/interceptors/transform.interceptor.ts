import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  data: T;
  meta: {
    timestamp: string;
  };
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => ({
        data: this.serializeBigInt(data),
        meta: {
          timestamp: new Date().toISOString(),
        },
      })),
    );
  }

  private serializeBigInt(obj: unknown): T {
    if (obj === null || obj === undefined) return obj as T;
    if (typeof obj === 'bigint') return Number(obj) as T;
    if (Array.isArray(obj)) return obj.map((item) => this.serializeBigInt(item)) as T;
    if (typeof obj === 'object') {
      const result: Record<string, unknown> = {};
      for (const [key, value] of Object.entries(obj)) {
        result[key] = this.serializeBigInt(value);
      }
      return result as T;
    }
    return obj as T;
  }
}
