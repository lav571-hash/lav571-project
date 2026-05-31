import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Course, CourseStatus, CourseLevel, CourseType } from '../database/entities/course.entity';
import { Session } from '../database/entities/session.entity';
import { Material } from '../database/entities/material.entity';
import { Booking, BookingStatus } from '../database/entities/booking.entity';
import { User, UserRole } from '../database/entities/user.entity';
import { CreateCourseDto } from './dto/create-course.dto';
import { CreateSessionDto } from './dto/create-session.dto';
import { AddMaterialDto } from './dto/add-material.dto';

@Injectable()
export class CoursesService {
  constructor(
    @InjectRepository(Course) private readonly courseRepo: Repository<Course>,
    @InjectRepository(Session) private readonly sessionRepo: Repository<Session>,
    @InjectRepository(Material) private readonly materialRepo: Repository<Material>,
    @InjectRepository(Booking) private readonly bookingRepo: Repository<Booking>,
  ) {}

  async create(dto: CreateCourseDto): Promise<Course> {
    const course = this.courseRepo.create(dto);
    return this.courseRepo.save(course);
  }

  async findAll(filters?: {
    level?: CourseLevel;
    type?: CourseType;
    status?: CourseStatus;
    teacherId?: string;
  }): Promise<Course[]> {
    const query = this.courseRepo.createQueryBuilder('c')
      .leftJoinAndSelect('c.teacher', 'teacher')
      .leftJoinAndSelect('c.sessions', 'sessions')
      .orderBy('c.createdAt', 'DESC');

    if (filters?.level) query.andWhere('c.level = :level', { level: filters.level });
    if (filters?.type) query.andWhere('c.type = :type', { type: filters.type });
    if (filters?.status) query.andWhere('c.status = :status', { status: filters.status });
    if (filters?.teacherId) query.andWhere('c.teacherId = :teacherId', { teacherId: filters.teacherId });

    return query.getMany();
  }

  async findPublished(): Promise<Course[]> {
    return this.findAll({ status: CourseStatus.PUBLISHED });
  }

  async findOne(id: string): Promise<Course> {
    const course = await this.courseRepo.findOne({
      where: { id },
      relations: { teacher: true, sessions: true, materials: true },
    });
    if (!course) throw new NotFoundException('Курс не найден');
    return course;
  }

  async update(id: string, dto: Partial<CreateCourseDto>): Promise<Course> {
    const course = await this.findOne(id);
    Object.assign(course, dto);
    return this.courseRepo.save(course);
  }

  async publish(id: string): Promise<Course> {
    const course = await this.findOne(id);
    course.status = CourseStatus.PUBLISHED;
    return this.courseRepo.save(course);
  }

  async archive(id: string): Promise<Course> {
    const course = await this.findOne(id);
    course.status = CourseStatus.ARCHIVED;
    return this.courseRepo.save(course);
  }

  async uploadPhoto(id: string, photoUrl: string): Promise<Course> {
    const course = await this.findOne(id);
    course.photoUrl = photoUrl;
    return this.courseRepo.save(course);
  }

  async addSession(courseId: string, dto: CreateSessionDto): Promise<Session> {
    await this.findOne(courseId);
    const session = this.sessionRepo.create({ courseId, ...dto });
    return this.sessionRepo.save(session);
  }

  async getSessions(courseId: string): Promise<Session[]> {
    await this.findOne(courseId);
    return this.sessionRepo.find({
      where: { courseId },
      order: { startsAt: 'ASC' },
    });
  }

  async deleteSession(sessionId: string): Promise<void> {
    await this.sessionRepo.delete(sessionId);
  }

  async addMaterial(courseId: string, dto: AddMaterialDto): Promise<Material> {
    await this.findOne(courseId);
    const material = this.materialRepo.create({ courseId, ...dto });
    return this.materialRepo.save(material);
  }

  async getMaterials(courseId: string): Promise<Material[]> {
    return this.materialRepo.find({
      where: { courseId },
      order: { order: 'ASC' },
    });
  }

  async deleteMaterial(materialId: string): Promise<void> {
    await this.materialRepo.delete(materialId);
  }

  async getAvailableSeats(courseId: string): Promise<number> {
    const course = await this.findOne(courseId);
    const confirmed = await this.bookingRepo.count({
      where: [
        { courseId, status: BookingStatus.CONFIRMED },
        { courseId, status: BookingStatus.PENDING_PAYMENT },
      ],
    });
    return Math.max(0, course.capacity - confirmed);
  }
}
