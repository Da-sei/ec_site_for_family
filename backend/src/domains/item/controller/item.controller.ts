import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import * as path from 'path';
import * as fs from 'fs';

const UPLOAD_DIR = path.join(process.cwd(), 'uploads', 'items');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });
import { v4 as uuidv4 } from 'uuid';
import { ItemService } from '../service/item.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';
import { GroupMemberGuard } from '../../../common/guards/group-member.guard';
import { ItemOwnerGuard } from '../../../common/guards/item-owner.guard';
import type { ItemDetailDto, PaginatedItemsDto } from '../domain/dto/item.dto';
import { CreateItemDto, UpdateItemDto } from './dto/item.dto';

@Controller('items')
export class ItemController {
  constructor(private readonly itemService: ItemService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createItem(
    @Body() dto: CreateItemDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<ItemDetailDto> {
    return this.itemService.createItem(
      {
        title: dto.title,
        description: dto.description,
        categoryId: dto.categoryId,
        groupId: dto.groupId,
        deliveryMethods: dto.deliveryMethods,
      },
      user.sub,
    );
  }

  @Post(':id/images')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(ItemOwnerGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: UPLOAD_DIR,
        filename: (_req, file, cb) => {
          const ext = path.extname(file.originalname);
          cb(null, `${uuidv4()}${ext}`);
        },
      }),
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.startsWith('image/')) {
          cb(new BadRequestException('画像ファイルのみアップロード可能です'), false);
        } else {
          cb(null, true);
        }
      },
    }),
  )
  async uploadImage(
    @Param('id', ParseIntPipe) itemId: number,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ id: number; imageUrl: string; order: number }> {
    if (!file) {
      throw new BadRequestException('ファイルが必要です');
    }
    const imageUrl = `/uploads/items/${file.filename}`;
    return this.itemService.addImage(itemId, user.sub, imageUrl);
  }

  @Get()
  @UseGuards(GroupMemberGuard)
  async getItems(
    @Query('groupId', ParseIntPipe) groupId: number,
    @Query('keyword') keyword?: string,
    @Query('categoryId') categoryIdStr?: string,
    @Query('offset') offsetStr?: string,
    @Query('limit') limitStr?: string,
    @CurrentUser() _user?: JwtPayload,
  ): Promise<PaginatedItemsDto> {
    const offset = offsetStr ? parseInt(offsetStr, 10) : 0;
    const limit = Math.min(limitStr ? parseInt(limitStr, 10) : 20, 50);
    const categoryId = categoryIdStr ? parseInt(categoryIdStr, 10) : undefined;
    return this.itemService.getItems({ groupId, keyword, categoryId, offset, limit });
  }

  @Get(':id')
  @UseGuards(GroupMemberGuard)
  async getItemById(@Param('id', ParseIntPipe) id: number): Promise<ItemDetailDto> {
    return this.itemService.getItemById(id);
  }

  @Patch(':id')
  @UseGuards(ItemOwnerGuard)
  @HttpCode(HttpStatus.OK)
  async updateItem(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateItemDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<ItemDetailDto> {
    return this.itemService.updateItem(id, user.sub, dto);
  }

  @Delete(':id')
  @UseGuards(ItemOwnerGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteItem(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<void> {
    return this.itemService.deleteItem(id, user.sub);
  }
}
