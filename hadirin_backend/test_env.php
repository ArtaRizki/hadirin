<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';

echo "APP_KEY from env(): " . env('APP_KEY') . "\n";
echo "APP_KEY from config(): " . config('app.key') . "\n";
