<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Feedback extends Model
{
    protected $fillable = [
        'tenant_id',
        'user_id',
        'type',
        'content',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
