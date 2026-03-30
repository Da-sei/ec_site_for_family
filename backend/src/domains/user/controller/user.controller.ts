import { Controller, Get, Patch, Body, NotFoundException } from '@nestjs/common';
import { IsOptional, IsString, MinLength, MaxLength } from 'class-validator';
import { UserService } from '../service/user.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';

class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(50)
  name?: string;

  @IsOptional()
  @IsString()
  currentPassword?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  newPassword?: string;
}

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  // ユーザ情報の取得
  @Get('me')
  async getMe(@CurrentUser() user: JwtPayload): Promise<{ id: number; accountId: string; name: string }> {
    const profile = await this.userService.getProfile(user.sub);
    if (!profile) throw new NotFoundException('ユーザーが見つかりません');
    return { id: profile.id, accountId: profile.accountId, name: profile.name };
  }

  // ユーザ情報の更新
  @Patch('me')
  async updateMe(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateProfileDto,
  ): Promise<{ id: number; accountId: string; name: string }> {
    const updated = await this.userService.updateProfile(user.sub, dto);
    return { id: updated.id, accountId: updated.accountId, name: updated.name };
  }
}
