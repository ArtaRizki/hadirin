<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NgajiLog extends Model
{
    protected $fillable = [
        'tenant_id',
        'user_id',
        'ngaji_group_id',
        'location',
        'materi',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function group()
    {
        return $this->belongsTo(NgajiGroup::class, 'ngaji_group_id');
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
