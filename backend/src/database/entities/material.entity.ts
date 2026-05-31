import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { Course } from './course.entity';

export enum MaterialKind {
  PDF = 'pdf',
  VIDEO_LINK = 'video_link',
}

@Entity('materials')
export class Material {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'course_id' })
  courseId: string;

  @ManyToOne(() => Course, (course) => course.materials)
  @JoinColumn({ name: 'course_id' })
  course: Course;

  @Column({ type: 'enum', enum: MaterialKind })
  kind: MaterialKind;

  @Column()
  title: string;

  @Column()
  url: string;

  @Column({ type: 'int', default: 0 })
  order: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
