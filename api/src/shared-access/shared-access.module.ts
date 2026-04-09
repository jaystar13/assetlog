import { Module } from '@nestjs/common';
import { SharedAccessService } from './shared-access.service';
import { SharedAccessController } from './shared-access.controller';

@Module({
  providers: [SharedAccessService],
  controllers: [SharedAccessController],
})
export class SharedAccessModule {}
