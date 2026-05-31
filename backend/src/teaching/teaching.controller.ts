import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { TeachingService } from './teaching.service';
import { MarkAttendanceDto } from './dto/mark-attendance.dto';
import { CreateGradeDto } from './dto/create-grade.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole, User } from '../database/entities/user.entity';

@ApiTags('Преподавание')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('teaching')
export class TeachingController {
  constructor(private readonly teachingService: TeachingService) {}

  @Get('my-students')
  @Roles(UserRole.TEACHER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Мои ученики по курсам' })
  getMyStudents(@CurrentUser() user: User) {
    return this.teachingService.getMyStudents(user);
  }

  @Get('my-courses')
  @Roles(UserRole.TEACHER)
  @ApiOperation({ summary: 'Мои курсы' })
  getMyCourses(@CurrentUser() user: User) {
    return this.teachingService.getMyCourses(user);
  }

  @Post('attendance')
  @Roles(UserRole.TEACHER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Отметить посещаемость' })
  markAttendance(@CurrentUser() user: User, @Body() dto: MarkAttendanceDto) {
    return this.teachingService.markAttendance(user, dto);
  }

  @Get('attendance/booking/:bookingId')
  @Roles(UserRole.TEACHER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Посещаемость по брони' })
  attendanceByBooking(@Param('bookingId') bookingId: string) {
    return this.teachingService.getAttendanceByBooking(bookingId);
  }

  @Get('attendance/session/:sessionId')
  @Roles(UserRole.TEACHER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Посещаемость занятия' })
  attendanceBySession(@Param('sessionId') sessionId: string) {
    return this.teachingService.getAttendanceBySession(sessionId);
  }

  @Post('grades')
  @Roles(UserRole.TEACHER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Поставить оценку' })
  createGrade(@CurrentUser() user: User, @Body() dto: CreateGradeDto) {
    return this.teachingService.createGrade(user, dto);
  }

  @Get('grades/booking/:bookingId')
  @ApiOperation({ summary: 'Оценка по брони' })
  gradeByBooking(@Param('bookingId') bookingId: string) {
    return this.teachingService.getGradesByBooking(bookingId);
  }
}
