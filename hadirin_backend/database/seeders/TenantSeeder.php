<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class TenantSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        \App\Models\Tenant::create([
            'id' => 'SDIT-PALU',
            'name' => 'SDIT Al-Fahmi Palu',
            'radius' => 100,
            'batas_jam_masuk' => 7,
        ]);

        \App\Models\Tenant::create([
            'id' => 'SMA-PGRI',
            'name' => 'SMA PGRI Majalengka',
            'radius' => 150,
            'batas_jam_masuk' => 7,
        ]);
    }
}
