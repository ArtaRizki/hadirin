<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuranLog extends Model
{
    protected $fillable = [
        'tenant_id',
        'user_id',
        'student_nis',
        'quran_master_id',
        'halaman_ayat',
        'nilai',
        'keterangan',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function quranMaster()
    {
        return $this->belongsTo(QuranMaster::class);
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
