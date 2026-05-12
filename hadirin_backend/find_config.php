<?php
require 'vendor/autoload.php';
use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = 'd:/INFORMATICS/FREELANCE/hadirin/sdit-palu.xlsx';
$spreadsheet = IOFactory::load($filePath);
$sheet = $spreadsheet->getSheetByName('Config_Kantor');
$data = $sheet->toArray();

foreach ($data as $index => $row) {
    if (array_filter($row)) {
        echo "Row $index: " . json_encode($row) . "\n";
    }
}
