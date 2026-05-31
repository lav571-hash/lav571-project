import { IsEnum, IsString, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { MaterialKind } from '../../database/entities/material.entity';

export class AddMaterialDto {
  @ApiProperty({ enum: MaterialKind })
  @IsEnum(MaterialKind)
  kind: MaterialKind;

  @ApiProperty()
  @IsString()
  title: string;

  @ApiProperty()
  @IsString()
  url: string;

  @ApiProperty({ required: false, default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  order?: number;
}
