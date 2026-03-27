import {
  IsString,
  IsOptional,
  MaxLength,
  IsNotEmpty,
  IsInt,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateWishlistItemDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsInt()
  @Type(() => Number)
  groupId: number;
}

export class UpdateWishlistItemDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  description?: string;
}
