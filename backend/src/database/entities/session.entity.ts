import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { Course } from './course.entity';
import { Attendance } from './attendance.entity';

@Entity('sessions')
export class Session {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'course_id' })
  courseId: string;

  @ManyToOne(() => Course, (course) => course.sessions)
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt: Date;

  @Column({ name: 'duration_min' })
  durationMin: number;

  @Column({ nullable: true })
  location: string;

  @OneToMany(() => Attendance, (attendance) => attendance.session)
  attendances: Attendance[];
}
