import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ShareGroupsService } from './share-groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { InviteToGroupDto } from './dto/invite-to-group.dto';
import { ShareItemsDto } from './dto/share-items.dto';
import { UpdateMemberRoleDto } from './dto/update-member-role.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('ShareGroups')
@ApiBearerAuth()
@Controller('share-groups')
export class ShareGroupsController {
  constructor(private service: ShareGroupsService) {}

  // ─── 그룹 CRUD ─────────────────────────────────

  @Post()
  @ApiOperation({ summary: '공유 그룹 생성' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateGroupDto) {
    return this.service.create(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: '내가 속한 그룹 목록' })
  findMyGroups(@CurrentUser('id') userId: string) {
    return this.service.findMyGroups(userId);
  }

  @Get(':id')
  @ApiOperation({ summary: '그룹 상세 (멤버 목록)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.findOne(userId, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: '그룹 이름 수정 (admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  update(@CurrentUser('id') userId: string, @Param('id') id: string, @Body() dto: CreateGroupDto) {
    return this.service.update(userId, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '그룹 삭제 (admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.remove(userId, id);
  }

  // ─── 멤버 관리 ─────────────────────────────────

  @Post(':id/invite')
  @ApiOperation({ summary: '그룹에 사용자 초대 (admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  invite(
    @CurrentUser() user: { id: string; email: string },
    @Param('id') id: string,
    @Body() dto: InviteToGroupDto,
  ) {
    return this.service.invite(user.id, user.email, id, dto);
  }

  @Patch(':id/members/:memberId')
  @ApiOperation({ summary: '멤버 역할 변경 (admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  @ApiParam({ name: 'memberId', description: '멤버 ID' })
  updateMemberRole(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Param('memberId') memberId: string,
    @Body() dto: UpdateMemberRoleDto,
  ) {
    return this.service.updateMemberRole(userId, id, memberId, dto);
  }

  @Delete(':id/members/:memberId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '멤버 제거 (admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  @ApiParam({ name: 'memberId', description: '멤버 ID' })
  removeMember(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Param('memberId') memberId: string,
  ) {
    return this.service.removeMember(userId, id, memberId);
  }

  @Post(':id/leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '그룹 탈퇴 (non-admin)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  leaveGroup(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.service.leaveGroup(userId, id);
  }

  // ─── 항목 공유 ─────────────────────────────────

  @Post(':id/items')
  @ApiOperation({ summary: '항목 공유 (batch)' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  shareItems(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: ShareItemsDto,
  ) {
    return this.service.shareItems(userId, id, dto);
  }

  @Delete(':id/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '항목 공유 해제' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  @ApiParam({ name: 'itemId', description: '공유 항목 ID (SharedItem.id)' })
  unshareItem(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Param('itemId') itemId: string,
  ) {
    return this.service.unshareItem(userId, id, itemId);
  }

  // ─── 공유 데이터 조회 ──────────────────────────

  @Get(':id/transactions')
  @ApiOperation({ summary: '그룹에 공유된 거래 조회' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  @ApiQuery({ name: 'month', required: false, example: '2026-04' })
  getGroupTransactions(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('month') month?: string,
  ) {
    return this.service.getGroupTransactions(userId, id, month);
  }

  @Get(':id/assets')
  @ApiOperation({ summary: '그룹에 공유된 자산 조회' })
  @ApiParam({ name: 'id', description: '그룹 ID' })
  @ApiQuery({ name: 'month', required: false, example: '2026-04' })
  getGroupAssets(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Query('month') month?: string,
  ) {
    return this.service.getGroupAssets(userId, id, month);
  }

  // ─── 초대 수신 ─────────────────────────────────

  @Get('invitations/received')
  @ApiOperation({ summary: '받은 그룹 초대 목록' })
  findReceivedInvitations(@CurrentUser('email') email: string) {
    return this.service.findReceivedInvitations(email);
  }

  @Post('invitations/:invId/accept')
  @ApiOperation({ summary: '그룹 초대 수락' })
  @ApiParam({ name: 'invId', description: '초대 ID' })
  acceptInvitation(
    @CurrentUser() user: { id: string; email: string },
    @Param('invId') invId: string,
  ) {
    return this.service.acceptInvitation(user.id, user.email, invId);
  }

  @Post('invitations/:invId/decline')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '그룹 초대 거절' })
  @ApiParam({ name: 'invId', description: '초대 ID' })
  declineInvitation(
    @CurrentUser('email') email: string,
    @Param('invId') invId: string,
  ) {
    return this.service.declineInvitation(email, invId);
  }
}
