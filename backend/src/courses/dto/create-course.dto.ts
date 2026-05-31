import {
  IsString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  Min,
  IsUUID,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { CourseLevel, CourseType } from '../../database/entities/course.entity';

export class CreateCourseDto {
  @ApiProperty()
  @IsString()
  title: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ enum: CourseLevel })
  @IsEnum(CourseLevel)
  level: CourseLevel;

  @ApiProperty({ enum: CourseType })
  @IsEnum(CourseType)
  type: CourseType;

  @ApiProperty()
  @IsUUID()
  teacherId: string;

  @ApiProperty({ minimum: 1 })
  @IsNumber()
  @IsPositive()
  capacity: number;

  @ApiProperty({ minimum: 0 })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  program?: string;
}
