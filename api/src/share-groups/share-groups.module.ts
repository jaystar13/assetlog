import { Module } from '@nestjs/common';
import { ShareGroupsService } from './share-groups.service';
import { ShareGroupsController } from './share-groups.controller';

@Module({
  providers: [ShareGroupsService],
  controllers: [ShareGroupsController],
})
export class ShareGroupsModule {}
