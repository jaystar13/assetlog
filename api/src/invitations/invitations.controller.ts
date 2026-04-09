import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { InvitationsService } from './invitations.service';
import { CreateInvitationDto } from './dto/create-invitation.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Invitations')
@ApiBearerAuth()
@Controller('invitations')
export class InvitationsController {
  constructor(private invitationsService: InvitationsService) {}

  @Post()
  @ApiOperation({ summary: '초대 생성' })
  create(
    @CurrentUser() user: { id: string; email: string },
    @Body() dto: CreateInvitationDto,
  ) {
    return this.invitationsService.create(user.id, user.email, dto);
  }

  @Get('sent')
  @ApiOperation({ summary: '보낸 초대 목록' })
  findSent(@CurrentUser('id') userId: string) {
    return this.invitationsService.findSent(userId);
  }

  @Get('received')
  @ApiOperation({ summary: '받은 초대 목록' })
  findReceived(@CurrentUser('email') email: string) {
    return this.invitationsService.findReceived(email);
  }

  @Post(':id/accept')
  @ApiOperation({ summary: '초대 수락 → 공유 관계 생성' })
  @ApiParam({ name: 'id', description: '초대 ID' })
  accept(
    @CurrentUser() user: { id: string; email: string },
    @Param('id') id: string,
  ) {
    return this.invitationsService.accept(user.id, user.email, id);
  }

  @Post(':id/decline')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '초대 거절' })
  @ApiParam({ name: 'id', description: '초대 ID' })
  decline(
    @CurrentUser('email') email: string,
    @Param('id') id: string,
  ) {
    return this.invitationsService.decline(email, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '보낸 초대 취소' })
  @ApiParam({ name: 'id', description: '초대 ID' })
  cancel(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
  ) {
    return this.invitationsService.cancel(userId, id);
  }
}
