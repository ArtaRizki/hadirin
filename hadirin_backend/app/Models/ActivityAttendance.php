<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityAttendance extends Model
{
    protected $fillable = [
        'activity_id',
        'user_id',
        'status',
    ];

    public function activity()
    {
        return $this->belongsTo(Activity::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
