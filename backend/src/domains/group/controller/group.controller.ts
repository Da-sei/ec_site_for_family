import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { GroupService } from '../service/group.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';
import type { GroupDto, GroupMemberDto, CreateGroupDto, JoinGroupDto } from './group.dto';

@Controller('groups')
export class GroupController {
  constructor(private readonly groupService: GroupService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createGroup(
    @Body() body: CreateGroupDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupDto> {
    if (!body.name || body.name.trim().length === 0) {
      throw new Error('グループ名は必須です');
    }
    const group = await this.groupService.createGroup(body.name.trim(), user.sub);
    return {
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      createdAt: group.createdAt,
    };
  }

  @Post(':id/invite')
  @HttpCode(HttpStatus.CREATED)
  async issueInviteToken(
    @Param('id', ParseIntPipe) groupId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ token: string; expiresAt: Date }> {
    return this.groupService.issueInviteToken(groupId, user.sub);
  }

  @Post('join')
  @HttpCode(HttpStatus.OK)
  async joinGroup(
    @Body() body: JoinGroupDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupMemberDto> {
    const member = await this.groupService.joinGroup(body.token, user.sub);
    return {
      groupId: member.groupId,
      userId: member.userId,
      joinedAt: member.joinedAt,
    };
  }

  @Get('mine')
  @HttpCode(HttpStatus.OK)
  async getMyGroups(@CurrentUser() user: JwtPayload): Promise<GroupDto[]> {
    const groups = await this.groupService.getMyGroups(user.sub);
    return groups.map((g) => ({
      id: g.id,
      name: g.name,
      ownerId: g.ownerId,
      createdAt: g.createdAt,
    }));
  }
}
