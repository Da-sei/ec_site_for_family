import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FavoriteService } from '../service/favorite.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';

@Controller('favorites')
export class FavoriteController {
  constructor(private readonly favoriteService: FavoriteService) {}

  @Post(':itemId')
  @HttpCode(HttpStatus.CREATED)
  async add(
    @CurrentUser() user: JwtPayload,
    @Param('itemId', ParseIntPipe) itemId: number,
  ): Promise<void> {
    await this.favoriteService.addFavorite(user.sub, itemId);
  }

  @Delete(':itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: JwtPayload,
    @Param('itemId', ParseIntPipe) itemId: number,
  ): Promise<void> {
    await this.favoriteService.removeFavorite(user.sub, itemId);
  }

  @Get()
  async getMyFavorites(@CurrentUser() user: JwtPayload) {
    const items = await this.favoriteService.getMyFavorites(user.sub);
    return items;
  }

  @Get(':itemId/status')
  async getStatus(
    @CurrentUser() user: JwtPayload,
    @Param('itemId', ParseIntPipe) itemId: number,
  ): Promise<{ isFavorited: boolean }> {
    const isFavorited = await this.favoriteService.isFavorited(user.sub, itemId);
    return { isFavorited };
  }
}
