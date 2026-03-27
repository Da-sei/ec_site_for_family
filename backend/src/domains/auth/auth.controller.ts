import {
  Controller,
  Post,
  Body,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { Public } from './decorators/public.decorator';

interface RegisterDto {
  name: string;
  password: string;
}

interface LoginDto {
  accountId: string;
  password: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('register')
  async register(@Body() dto: RegisterDto): Promise<{ accountId: string; accessToken: string }> {
    if (!dto.name || dto.name.trim().length === 0) {
      throw new BadRequestException('name は必須です');
    }
    if (!dto.password || dto.password.length < 8) {
      throw new BadRequestException('password は 8 文字以上必要です');
    }

    return this.authService.register(dto.name, dto.password);
  }

  @Public()
  @Post('login')
  async login(@Body() dto: LoginDto): Promise<{ accessToken: string }> {
    const user = await this.authService.validateUser(dto.accountId, dto.password);
    if (!user) {
      throw new UnauthorizedException('アカウントIDまたはパスワードが正しくありません');
    }
    return this.authService.login(user);
  }
}
