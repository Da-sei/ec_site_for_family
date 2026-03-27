import {
  IsString,
  IsOptional,
  IsNumber,
  IsArray,
  ArrayMinSize,
  IsEnum,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';
import type { DeliveryMethod } from './../../domain/type/item.repository.type';
import { DeliveryMethodEnum } from './../enum/item.enum';


export class CreateItemDto {
  @IsString()
  @MaxLength(200)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @Type(() => Number)
  categoryId: number;

  @IsNumber()
  @Type(() => Number)
  groupId: number;

  @IsOptional()
  @IsArray()
  @IsEnum(DeliveryMethodEnum, { each: true })
  deliveryMethods?: DeliveryMethod[];
}

export class UpdateItemDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  categoryId?: number;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @IsEnum(DeliveryMethodEnum, { each: true })
  deliveryMethods?: DeliveryMethod[];
}
