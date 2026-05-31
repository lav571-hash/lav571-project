import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Optional,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { CoursesService } from './courses.service';
import { CreateCourseDto } from './dto/create-course.dto';
import { CreateSessionDto } from './dto/create-session.dto';
import { AddMaterialDto } from './dto/add-material.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Public } from '../common/decorators/public.decorator';
import { UserRole } from '../database/entities/user.entity';
import { CourseLevel, CourseStatus, CourseType } from '../database/entities/course.entity';

@ApiTags('Курсы')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('courses')
export class CoursesController {
  constructor(private readonly coursesService: CoursesService) {}

  @Post()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Создать курс' })
  create(@Body() dto: CreateCourseDto) {
    return this.coursesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Каталог курсов' })
  @ApiQuery({ name: 'level', enum: CourseLevel, required: false })
  @ApiQuery({ name: 'type', enum: CourseType, required: false })
  @ApiQuery({ name: 'status', enum: CourseStatus, required: false })
  @ApiQuery({ name: 'teacherId', required: false })
  findAll(
    @Query('level') level?: CourseLevel,
    @Query('type') type?: CourseType,
    @Query('status') status?: CourseStatus,
    @Query('teacherId') teacherId?: string,
  ) {
    return this.coursesService.findAll({ level, type, status, teacherId });
  }

  @Get('published')
  @Public()
  @ApiOperation({ summary: 'Опубликованные курсы (публичный доступ)' })
  findPublished() {
    return this.coursesService.findPublished();
  }

  @Get(':id')
  @Public()
  @ApiOperation({ summary: 'Подробности курса (публичный доступ)' })
  findOne(@Param('id') id: string) {
    return this.coursesService.findOne(id);
  }

  @Get(':id/seats')
  @Public()
  @ApiOperation({ summary: 'Количество свободных мест (публичный доступ)' })
  getSeats(@Param('id') id: string) {
    return this.coursesService.getAvailableSeats(id).then((seats) => ({ seats }));
  }

  @Get(':id/sessions')
  @Public()
  @ApiOperation({ summary: 'Расписание занятий курса (публичный доступ)' })
  getSessions(@Param('id') id: string) {
    return this.coursesService.getSessions(id);
  }

  @Get(':id/materials')
  @Public()
  @ApiOperation({ summary: 'Учебные материалы курса (публичный доступ)' })
  getMaterials(@Param('id') id: string) {
    return this.coursesService.getMaterials(id);
  }

  @Patch(':id')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Обновить курс' })
  update(@Param('id') id: string, @Body() dto: Partial<CreateCourseDto>) {
    return this.coursesService.update(id, dto);
  }

  @Patch(':id/publish')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Опубликовать курс' })
  publish(@Param('id') id: string) {
    return this.coursesService.publish(id);
  }

  @Patch(':id/archive')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Архивировать курс' })
  archive(@Param('id') id: string) {
    return this.coursesService.archive(id);
  }

  // Sessions
  @Post(':id/sessions')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Добавить занятие к курсу' })
  addSession(@Param('id') id: string, @Body() dto: CreateSessionDto) {
    return this.coursesService.addSession(id, dto);
  }

  @Delete(':id/sessions/:sessionId')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Удалить занятие' })
  deleteSession(@Param('sessionId') sessionId: string) {
    return this.coursesService.deleteSession(sessionId);
  }

  // Materials
  @Post(':id/materials')
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @ApiOperation({ summary: 'Добавить материал к курсу' })
  addMaterial(@Param('id') id: string, @Body() dto: AddMaterialDto) {
    return this.coursesService.addMaterial(id, dto);
  }

  @Delete(':id/materials/:materialId')
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @ApiOperation({ summary: 'Удалить материал' })
  deleteMaterial(@Param('materialId') materialId: string) {
    return this.coursesService.deleteMaterial(materialId);
  }
}
