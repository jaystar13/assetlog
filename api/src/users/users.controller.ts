import { Controller, Get, Put, Patch, Delete, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpsertGoalDto } from './dto/upsert-goal.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Patch('me')
  @ApiOperation({ summary: '내 프로필 수정 (이름, 아바타)' })
  update(@CurrentUser('id') userId: string, @Body() dto: UpdateUserDto) {
    return this.usersService.update(userId, dto);
  }

  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: '회원 탈퇴 (계정 및 모든 데이터 삭제)' })
  remove(@CurrentUser('id') userId: string) {
    return this.usersService.remove(userId);
  }

  // ─────────────────────── Financial Goal ───────────────────────

  @Get('me/goal')
  @ApiOperation({ summary: '내 자산 목표 조회' })
  getGoal(@CurrentUser('id') userId: string) {
    return this.usersService.getGoal(userId);
  }

  @Put('me/goal')
  @ApiOperation({ summary: '내 자산 목표 설정/수정' })
  upsertGoal(@CurrentUser('id') userId: string, @Body() dto: UpsertGoalDto) {
    console.log('[Goal] upsertGoal dto:', JSON.stringify(dto));
    return this.usersService.upsertGoal(userId, dto);
  }
}
