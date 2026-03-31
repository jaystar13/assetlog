import { Module } from '@nestjs/common';
import { CardCompaniesController } from './card-companies.controller';

@Module({
  controllers: [CardCompaniesController],
})
export class CardCompaniesModule {}
