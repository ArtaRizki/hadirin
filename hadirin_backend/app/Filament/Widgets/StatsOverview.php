<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use App\Models\Tenant;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    public static function canView(): bool
    {
        return \Filament\Facades\Filament::getCurrentPanel()?->getId() === 'admin';
    }

    protected function getStats(): array
    {
        if (\Filament\Facades\Filament::getCurrentPanel()?->getId() !== 'admin') {
            return [];
        }

        return [
            Stat::make('Total Anggota', User::count())
                ->description('Semua instansi')
                ->descriptionIcon('heroicon-m-users')
                ->color('success'),
            Stat::make('Instansi Aktif', Tenant::count())
                ->description('Sekolah/Kantor')
                ->descriptionIcon('heroicon-m-building-office'),
            Stat::make('Hadir Hari Ini', Attendance::where('type', 'Masuk')->whereDate('created_at', today())->count())
                ->description('Check-in baru')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('warning'),
        ];
    }
}
