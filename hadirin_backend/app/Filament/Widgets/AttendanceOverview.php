<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;
use Filament\Facades\Filament;
use Carbon\Carbon;

class AttendanceOverview extends BaseWidget
{
    protected function getStats(): array
    {
        if (Filament::getCurrentPanel()?->getId() !== 'app') {
            return [];
        }

        $userId = auth()->id();
        $today = Carbon::today();

        $checkin = Attendance::where('user_id', $userId)
            ->whereDate('timestamp', $today)
            ->where('type', 'Masuk')
            ->first();

        $leave = Attendance::where('user_id', $userId)
            ->whereDate('timestamp', $today)
            ->whereIn('type', ['Izin', 'Sakit', 'Cuti'])
            ->first();

        return [
            Stat::make('Hadir Hari Ini', $checkin ? 'Jam ' . Carbon::parse($checkin->timestamp)->format('H:i') : 'Belum Absen')
                ->description($checkin ? 'Status: ' . $checkin->status : 'Silakan lakukan absen masuk')
                ->descriptionIcon($checkin ? 'heroicon-m-check-circle' : 'heroicon-m-x-circle')
                ->color($checkin ? 'success' : 'danger'),

            Stat::make('Izin / Sakit', $leave ? $leave->type : 'Tidak Ada')
                ->description($leave ? 'Alasan: ' . $leave->reason : 'Tetap sehat dan semangat!')
                ->descriptionIcon('heroicon-m-document-text')
                ->color($leave ? 'warning' : 'gray'),

            Stat::make('Status Pulang', $checkout ? 'Jam ' . Carbon::parse($checkout->timestamp)->format('H:i') : 'Belum Absen')
                ->description($checkout ? 'Sampai jumpa besok!' : 'Jangan lupa absen pulang')
                ->descriptionIcon($checkout ? 'heroicon-m-check-circle' : 'heroicon-m-clock')
                ->color($checkout ? 'success' : 'warning'),
        ];
    }
}
