<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::firstOrCreate([
            'id' => 1,
            'entity_credits' => [
                "x_ai" => [
                    "grok-2-1212" => ["credit" => 5000, "isUnlimited" => true],
                    "grok-2-vision-1212" => ["credit" => 5000, "isUnlimited" => true]
                ],
                "azure" => [
                    "azure" => ["credit" => 100, "isUnlimited" => true]
                ],
                // Additional JSON structure here
            ],
            'coingate_subscriber_id' => null,
            'team_id' => null,
            'team_manager_id' => null,
            'name' => 'Admin',
            'surname' => 'Admin',
            'email' => 'admin@admin.com',
            'phone' => '5555555555',
            'type' => 'super_admin',
            'password' => '$2y$10$XptdAOeFTxl7Yx2KmyfEluWY9Im6wpMIHoJ9V5yB96DgQgTafzzs6',
            'avatar' => 'assets/img/auth/default-avatar.png',
            'created_at' => '2025-04-29 09:48:38',
            'updated_at' => '2025-04-29 09:48:39',
            'affiliate_code' => 'P60NPGHAAFGD',
            'email_confirmed' => 0,
            'last_activity_at' => '2025-04-29 12:48:38',
            // Additional fields here
        ]);
          User::firstOrCreate([
            'id' => 2,
            'entity_credits' => [
                "x_ai" => [
                    "grok-2-1212" => ["credit" => 5000, "isUnlimited" => true],
                    "grok-2-vision-1212" => ["credit" => 5000, "isUnlimited" => true]
                ],
                "azure" => [
                    "azure" => ["credit" => 100, "isUnlimited" => true]
                ],
                // Additional JSON structure here
            ],
            'coingate_subscriber_id' => null,
            'team_id' => null,
            'team_manager_id' => null,
            'name' => 'Admin',
            'surname' => 'Arthur',
            'email' => 'arthur@admin.com',
            'phone' => '5555555555',
            'type' => 'super_admin',
            'password' => '$2y$10$XptdAOeFTxl7Yx2KmyfEluWY9Im6wpMIHoJ9V5yB96DgQgTafzzs6',
            'avatar' => 'assets/img/auth/default-avatar.png',
            'created_at' => '2025-04-29 09:48:38',
            'updated_at' => '2025-04-29 09:48:39',
            'affiliate_code' => 'P60NPGHAAFGD',
            'email_confirmed' => 0,
            'last_activity_at' => '2025-04-29 12:48:38',
            // Additional fields here
        ]);
           User::firstOrCreate([
            'id' => 3,
            'entity_credits' => [
                "x_ai" => [
                    "grok-2-1212" => ["credit" => 5000, "isUnlimited" => true],
                    "grok-2-vision-1212" => ["credit" => 5000, "isUnlimited" => true]
                ],
                "azure" => [
                    "azure" => ["credit" => 100, "isUnlimited" => true]
                ],
                // Additional JSON structure here
            ],
            'coingate_subscriber_id' => null,
            'team_id' => null,
            'team_manager_id' => null,
            'name' => 'Antônio',
            'surname' => 'Antônio',
            'email' => 'antonio@admin.com',
            'phone' => '5555555555',
            'type' => 'super_admin',
            'password' => '$2y$10$XptdAOeFTxl7Yx2KmyfEluWY9Im6wpMIHoJ9V5yB96DgQgTafzzs6',
            'avatar' => 'assets/img/auth/default-avatar.png',
            'created_at' => '2025-04-29 09:48:38',
            'updated_at' => '2025-04-29 09:48:39',
            'affiliate_code' => 'P60NPGHAAFGD',
            'email_confirmed' => 0,
            'last_activity_at' => '2025-04-29 12:48:38',
            // Additional fields here
        ]);
         User::firstOrCreate([
            'id' => 4,
            'entity_credits' => [
                "x_ai" => [
                    "grok-2-1212" => ["credit" => 5000, "isUnlimited" => true],
                    "grok-2-vision-1212" => ["credit" => 5000, "isUnlimited" => true]
                ],
                "azure" => [
                    "azure" => ["credit" => 100, "isUnlimited" => true]
                ],
                // Additional JSON structure here
            ],
            'coingate_subscriber_id' => null,
            'team_id' => null,
            'team_manager_id' => null,
            'name' => 'João',
            'surname' => 'João',
            'email' => 'joao@admin.com',
            'phone' => '5555555555',
            'type' => 'super_admin',
            'password' => '$2y$10$XptdAOeFTxl7Yx2KmyfEluWY9Im6wpMIHoJ9V5yB96DgQgTafzzs6',
            'avatar' => 'assets/img/auth/default-avatar.png',
            'created_at' => '2025-04-29 09:48:38',
            'updated_at' => '2025-04-29 09:48:39',
            'affiliate_code' => 'P60NPGHAAFGD',
            'email_confirmed' => 0,
            'last_activity_at' => '2025-04-29 12:48:38',
            // Additional fields here
        ]);
    }
}
