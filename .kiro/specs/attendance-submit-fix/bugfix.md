# Bugfix Requirements Document

## Introduction

When a user submits attendance via the web interface (`/attendances/create`), the page refreshes without recording the attendance and without showing any error or success message. This affects all users attempting to use the web-based attendance form. Three root causes have been identified: (1) the controller returns a JSON response to a regular HTML form POST, (2) a non-existent `notes` field is passed to `Attendance::create()`, and (3) time format parsing may fail if `limit_checkin` is stored without seconds.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN geofencing validation fails during a web form POST submission THEN the system returns a JSON response with HTTP 422 status instead of a proper HTML redirect, causing the browser to display a blank page or refresh without user feedback

1.2 WHEN the `storeWeb` method creates an attendance record with `'notes' => 'Via Web'` THEN the system attempts to mass-assign a field that does not exist in the `attendances` table schema and is not listed in the model's `$fillable` array, causing the field to be silently dropped (or an SQL error on strict mode databases)

1.3 WHEN `OfficeConfig.limit_checkin` is stored in `H:i` format (e.g., "07:00") THEN the system throws a Carbon `InvalidFormatException` because `Carbon::createFromFormat('H:i:s', ...)` expects seconds, resulting in a 500 error that manifests as a page refresh with no feedback

### Expected Behavior (Correct)

2.1 WHEN geofencing validation fails during a web form POST submission THEN the system SHALL redirect back to the previous page with a flash error message indicating the user is outside the allowed radius

2.2 WHEN the `storeWeb` method creates an attendance record THEN the system SHALL only persist fields that exist in the database schema and are listed in the model's `$fillable` array, successfully saving the attendance record

2.3 WHEN `OfficeConfig.limit_checkin` is stored in either `H:i` or `H:i:s` format THEN the system SHALL parse the time value correctly without throwing an exception, and determine the attendance status (Tepat Waktu/Terlambat) accurately

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a user submits attendance via the mobile API endpoint THEN the system SHALL CONTINUE TO process and respond with JSON as before

3.2 WHEN a user submits attendance from within the allowed geofence radius via the web form THEN the system SHALL CONTINUE TO save the attendance record and redirect to the dashboard with a success message

3.3 WHEN `OfficeConfig.limit_checkin` is already stored in `H:i:s` format (e.g., "07:00:00") THEN the system SHALL CONTINUE TO parse the time correctly and determine attendance status accurately

3.4 WHEN a user has already submitted attendance for the current day and type THEN the system SHALL CONTINUE TO prevent duplicate submissions via the `create` method validation
