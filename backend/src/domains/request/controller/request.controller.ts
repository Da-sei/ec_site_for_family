import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { RequestService } from '../service/request.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';
import type { RequestDto } from '../domain/dto/request.dto';
import type { CreateRequestDto } from './dto/request.dto';

@Controller('requests')
export class RequestController {
  constructor(private readonly requestService: RequestService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createRequest(
    @Body() body: CreateRequestDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto> {
    return this.requestService.createRequest(body.itemId, user.sub, body.deliveryMethod);
  }

  @Post(':id/approve')
  @HttpCode(HttpStatus.OK)
  async approveRequest(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto> {
    return this.requestService.approveRequest(id, user.sub);
  }

  @Post(':id/decline')
  @HttpCode(HttpStatus.OK)
  async declineRequest(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto> {
    return this.requestService.declineRequest(id, user.sub);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  async cancelRequest(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto> {
    return this.requestService.cancelRequest(id, user.sub);
  }

  @Post(':id/complete')
  @HttpCode(HttpStatus.OK)
  async completeRequest(
    @Param('id', ParseIntPipe) id: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto> {
    return this.requestService.completeRequest(id, user.sub);
  }

  @Get('history')
  async getHistory(@CurrentUser() user: JwtPayload): Promise<RequestDto[]> {
    return this.requestService.getHistory(user.sub);
  }

  @Get('my-requests')
  async getMyRequests(@CurrentUser() user: JwtPayload): Promise<RequestDto[]> {
    return this.requestService.getMyRequests(user.sub);
  }

  @Get()
  async getRequestsByItemId(
    @Query('itemId', ParseIntPipe) itemId: number,
    @CurrentUser() user: JwtPayload,
  ): Promise<RequestDto[]> {
    return this.requestService.getRequestsByItemId(itemId, user.sub);
  }
}
