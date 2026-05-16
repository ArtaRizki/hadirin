<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BriefingAttendance extends Model
{
    protected $fillable = ['briefing_id', 'user_id', 'status'];

    public function briefing()
    {
        return $this->belongsTo(Briefing::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
