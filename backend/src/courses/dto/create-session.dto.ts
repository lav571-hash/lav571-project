import { IsDateString, IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSessionDto {
  @ApiProperty({ example: '2026-06-15T10:00:00.000Z' })
  @IsDateString()
  startsAt: string;

  @ApiProperty({ example: 120 })
  @IsNumber()
  @IsPositive()
  durationMin: number;

  @ApiProperty({ required: false, example: 'Барбер-студия, ул. Примерная 1' })
  @IsOptional()
  @IsString()
  location?: string;
}
