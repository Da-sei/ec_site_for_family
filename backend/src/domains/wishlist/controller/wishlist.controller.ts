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
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { WishlistService } from '../service/wishlist.service';
import {
  CreateWishlistItemDto,
  UpdateWishlistItemDto,
} from './dto/wishlist.dto';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';
import { GroupMemberGuard } from '../../../common/guards/group-member.guard';
import { WishlistItemOwnerGuard } from '../../../common/guards/wishlist-item-owner.guard';

@Controller('wishlist')
export class WishlistController {
  constructor(private readonly wishlistService: WishlistService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateWishlistItemDto,
  ) {
    return this.wishlistService.createWishlistItem(user.sub, dto);
  }

  @Get()
  @UseGuards(GroupMemberGuard)
  async findAll(@Query('groupId', ParseIntPipe) groupId: number) {
    return this.wishlistService.getWishlistItems(groupId);
  }

  @Get(':id')
  async findOne(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.wishlistService.getWishlistItemById(id, user.sub);
  }

  @Patch(':id')
  @UseGuards(WishlistItemOwnerGuard)
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateWishlistItemDto,
  ) {
    return this.wishlistService.updateWishlistItem(id, dto);
  }

  @Delete(':id')
  @UseGuards(WishlistItemOwnerGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.wishlistService.deleteWishlistItem(id);
  }
}
