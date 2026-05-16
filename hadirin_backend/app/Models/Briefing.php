<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Briefing extends Model
{
    protected $fillable = [
        'tenant_id',
        'title',
        'scheduled_date',
        'scheduled_time',
        'description',
    ];

    protected $casts = [
        'scheduled_date' => 'date',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function attendances()
    {
        return $this->hasMany(BriefingAttendance::class);
    }
}
