import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { AssetsModule } from './assets/assets.module';
import { TransactionsModule } from './transactions/transactions.module';
import { CardCompaniesModule } from './card-companies/card-companies.module';
import { ImportModule } from './import/import.module';
import { ShareGroupsModule } from './share-groups/share-groups.module';
import { QuotesModule } from './quotes/quotes.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    UsersModule,
    AssetsModule,
    TransactionsModule,
    CardCompaniesModule,
    ImportModule,
    ShareGroupsModule,
    QuotesModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
