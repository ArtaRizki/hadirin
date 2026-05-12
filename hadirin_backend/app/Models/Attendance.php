<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    protected $fillable = [
        'tenant_id',
        'user_id',
        'type',
        'timestamp',
        'lat_long',
        'photo_url',
        'status',
        'is_valid',
        'reason',
        'leave_status',
        'substitute_teacher',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
