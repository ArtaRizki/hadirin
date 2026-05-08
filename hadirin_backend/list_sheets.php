<?php
require 'vendor/autoload.php';
use PhpOffice\PhpSpreadsheet\IOFactory;

$filePath = 'd:/INFORMATICS\FREELANCE/hadirin/sdit-palu.xlsx';
$spreadsheet = IOFactory::load($filePath);
echo json_encode($spreadsheet->getSheetNames(), JSON_PRETTY_PRINT);
