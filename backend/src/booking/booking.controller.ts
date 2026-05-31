import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole, User } from '../database/entities/user.entity';

@ApiTags('Записи')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('bookings')
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  @Post()
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Записаться на курс' })
  create(@CurrentUser() user: User, @Body() dto: CreateBookingDto) {
    return this.bookingService.create(user, dto);
  }

  @Get('my')
  @Roles(UserRole.STUDENT)
  @ApiOperation({ summary: 'Мои записи (ученик)' })
  myBookings(@CurrentUser() user: User) {
    return this.bookingService.findByStudent(user.id);
  }

  @Get()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Все записи (admin)' })
  findAll() {
    return this.bookingService.findAll();
  }

  @Get('course/:courseId')
  @Roles(UserRole.ADMIN, UserRole.TEACHER)
  @ApiOperation({ summary: 'Записи на конкретный курс' })
  byCourse(@Param('courseId') courseId: string) {
    return this.bookingService.findByCourse(courseId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Детали записи' })
  findOne(@Param('id') id: string) {
    return this.bookingService.findOne(id);
  }

  @Patch(':id/confirm-payment')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Подтвердить оплату (admin)' })
  confirmPayment(@Param('id') id: string, @CurrentUser() admin: User) {
    return this.bookingService.confirmPayment(id, admin);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Отменить запись (ученик до оплаты / admin после оплаты)' })
  cancel(
    @Param('id') id: string,
    @Body() dto: CancelBookingDto,
    @CurrentUser() user: User,
  ) {
    if (user.role === UserRole.ADMIN) {
      return this.bookingService.cancelByAdmin(id, user, dto);
    }
    return this.bookingService.cancelByStudent(id, user, dto);
  }
}
