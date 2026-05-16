<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuranStudent extends Model
{
    protected $fillable = ['tenant_id', 'nis', 'name', 'class'];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
