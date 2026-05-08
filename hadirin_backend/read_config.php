<?php
require 'vendor/autoload.php';
use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = 'd:/INFORMATICS/FREELANCE/hadirin/sdit-palu.xlsx';
$spreadsheet = IOFactory::load($filePath);
$sheet = $spreadsheet->getSheetByName('Config_Kantor');
$data = $sheet->toArray();

echo json_encode(array_slice($data, 0, 5), JSON_PRETTY_PRINT);
