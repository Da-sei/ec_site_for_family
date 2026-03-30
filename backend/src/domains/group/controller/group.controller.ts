import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { GroupService } from '../service/group.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';
import type {
  GroupDto,
  GroupMemberDto,
  GroupMemberDetailDto,
  CreateGroupDto,
  UpdateGroupDto,
  JoinGroupDto,
  TransferOwnerDto,
} from './group.dto';

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
    return { id: group.id, name: group.name, ownerId: group.ownerId, createdAt: group.createdAt };
  }

  @Get('mine')
  @HttpCode(HttpStatus.OK)
  async getMyGroups(@CurrentUser() user: JwtPayload): Promise<GroupDto[]> {
    const groups = await this.groupService.getMyGroups(user.sub);
    return groups.map((g) => ({ id: g.id, name: g.name, ownerId: g.ownerId, createdAt: g.createdAt }));
  }

  @Get(':id/members')
  @HttpCode(HttpStatus.OK)
  async getMembers(
    @Param('id', ParseIntPipe) groupId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupMemberDetailDto[]> {
    const members = await this.groupService.getMembers(groupId, user.sub);
    const group = await this.groupService.getMyGroups(user.sub);
    const g = group.find((g) => g.id === groupId);
    const ownerId = g?.ownerId ?? -1;
    return members.map((m) => ({
      userId: m.userId,
      accountId: m.accountId,
      name: m.name,
      joinedAt: m.joinedAt,
      isOwner: m.userId === ownerId,
    }));
  }

  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  async updateGroup(
    @Param('id', ParseIntPipe) groupId: number,
    @Body() body: UpdateGroupDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupDto> {
    const group = await this.groupService.updateGroup(groupId, body.name, user.sub);
    return { id: group.id, name: group.name, ownerId: group.ownerId, createdAt: group.createdAt };
  }

  @Post(':id/invite')
  @HttpCode(HttpStatus.CREATED)
  async issueInviteToken(
    @Param('id', ParseIntPipe) groupId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ token: string; expiresAt: Date }> {
    return this.groupService.issueInviteToken(groupId, user.sub);
  }

  @Post(':id/leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  async leaveGroup(
    @Param('id', ParseIntPipe) groupId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<void> {
    await this.groupService.leaveGroup(groupId, user.sub);
  }

  @Delete(':id/members/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeMember(
    @Param('id', ParseIntPipe) groupId: number,
    @Param('userId', ParseIntPipe) targetUserId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<void> {
    await this.groupService.removeGroupMember(groupId, targetUserId, user.sub);
  }

  @Patch(':id/owner')
  @HttpCode(HttpStatus.OK)
  async transferOwner(
    @Param('id', ParseIntPipe) groupId: number,
    @Body() body: TransferOwnerDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupDto> {
    const group = await this.groupService.transferOwner(groupId, body.newOwnerId, user.sub);
    return { id: group.id, name: group.name, ownerId: group.ownerId, createdAt: group.createdAt };
  }

  @Post('join')
  @HttpCode(HttpStatus.OK)
  async joinGroup(
    @Body() body: JoinGroupDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<GroupMemberDto> {
    const member = await this.groupService.joinGroup(body.token, user.sub);
    return { groupId: member.groupId, userId: member.userId, joinedAt: member.joinedAt };
  }
}
