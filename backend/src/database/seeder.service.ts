import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from './entities/user.entity';
import { Setting } from './entities/setting.entity';

@Injectable()
export class SeederService implements OnApplicationBootstrap {
  private readonly logger = new Logger(SeederService.name);

  constructor(
    @InjectRepository(User) private readonly userRepo: Repository<User>,
    @InjectRepository(Setting) private readonly settingRepo: Repository<Setting>,
  ) {}

  async onApplicationBootstrap() {
    await this.seedAdmin();
    await this.seedSettings();
  }

  private async seedAdmin() {
    const email = process.env.ADMIN_EMAIL ?? 'admin@barber.academy';
    const password = process.env.ADMIN_PASSWORD ?? 'Admin1234!';

    const existing = await this.userRepo.findOne({ where: { email } });
    if (existing) {
      this.logger.log(`Admin уже существует: ${email}`);
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const admin = this.userRepo.create({
      email,
      fullName: 'Администратор',
      passwordHash,
      role: UserRole.ADMIN,
      isActive: true,
    });
    await this.userRepo.save(admin);
    this.logger.log(`✅ Admin создан: ${email} / ${password}`);
  }

  private async seedSettings() {
    const defaults: Array<{ key: string; value: string; description: string }> = [
      {
        key: 'booking_hold_hours',
        value: '24',
        description: 'Количество часов, через которые неоплаченная бронь снимается автоматически',
      },
    ];

    for (const { key, value, description } of defaults) {
      const exists = await this.settingRepo.findOne({ where: { key } });
      if (!exists) {
        await this.settingRepo.save(this.settingRepo.create({ key, value, description }));
        this.logger.log(`Setting создан: ${key} = ${value}`);
      }
    }
  }
}
