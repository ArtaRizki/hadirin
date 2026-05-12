<?php
require 'vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = 'd:/INFORMATICS/FREELANCE/hadirin/sdit-palu.xlsx';
$spreadsheet = IOFactory::load($filePath);
$sheet = $spreadsheet->getActiveSheet();
$data = $sheet->toArray();

echo json_encode(array_slice($data, 0, 10), JSON_PRETTY_PRINT);
