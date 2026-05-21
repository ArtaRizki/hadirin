# Bugfix Requirements Document

## Introduction

When a user submits attendance (absen masuk/pulang), the page refreshes without recording the attendance. This bug is present in the deployed version (https://sditalfahmipalu.great-site.net). The root cause is in `api_client.dart`: the `sendRequest` method constructs the correct URL using `AppConfig.baseUrl` but then ignores it and attempts to send the HTTP request to `AppConfig.gasEndpoint` — a property that does not exist in `AppConfig`. This is leftover code from a migration from Google Apps Script to Laravel. Additionally, the code references an undefined variable `actionName`. The result is a runtime error that is caught silently, causing the UI to show a failure/refresh without saving attendance.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `sendRequest` is called with any endpoint and payload THEN the system attempts to access `AppConfig.gasEndpoint` which does not exist in the `AppConfig` class, causing a compilation/runtime error

1.2 WHEN `sendRequest` is called THEN the system references an undefined variable `actionName` in the URL construction fallback path, causing a runtime error

1.3 WHEN the attendance submission request fails due to the incorrect endpoint THEN the system catches the error silently and returns a failure result, causing the UI to refresh without recording attendance

### Expected Behavior (Correct)

2.1 WHEN `sendRequest` is called with an endpoint and payload THEN the system SHALL send the HTTP POST request to `AppConfig.baseUrl/$endpoint` (the correctly constructed Laravel API URL)

2.2 WHEN `sendRequest` is called THEN the system SHALL use the `endpoint` parameter passed to the method for URL construction, not any undefined or legacy variables

2.3 WHEN the attendance submission request succeeds (HTTP 200) THEN the system SHALL return the server response so the UI can display a success confirmation and record the attendance

### Unchanged Behavior (Regression Prevention)

3.1 WHEN `sendRequest` is called THEN the system SHALL CONTINUE TO use the 45-second timeout (or custom timeout if provided)

3.2 WHEN `sendRequest` is called THEN the system SHALL CONTINUE TO send the payload as JSON with `Content-Type: application/json` and `Accept: application/json` headers

3.3 WHEN `sendRequest` is called THEN the system SHALL CONTINUE TO log the request URL and sanitized payload (hiding foto_base64, face_embedding, face_descriptor)

3.4 WHEN `sendRequest` encounters a network error THEN the system SHALL CONTINUE TO rethrow the exception so callers can handle it appropriately

3.5 WHEN `parseResponse` receives a valid JSON response THEN the system SHALL CONTINUE TO parse it and return success/failure based on the response code/status

---

## Bug Condition (Formal)

```pascal
FUNCTION isBugCondition(X)
  INPUT: X of type SendRequestCall (endpoint: String, payload: Map)
  OUTPUT: boolean
  
  // The bug triggers on EVERY call to sendRequest because the method
  // always uses the non-existent AppConfig.gasEndpoint instead of the
  // correctly constructed URL.
  RETURN true
END FUNCTION
```

```pascal
// Property: Fix Checking - Correct Endpoint Usage
FOR ALL X WHERE isBugCondition(X) DO
  result ← sendRequest'(X.endpoint, X.payload)
  ASSERT request_was_sent_to(AppConfig.baseUrl + "/" + X.endpoint)
  AND response_is_returned(result)
END FOR
```

```pascal
// Property: Preservation Checking
FOR ALL X WHERE NOT isBugCondition(X) DO
  ASSERT F(X) = F'(X)
END FOR
```

Note: Since the bug condition is `true` for all inputs (every request is affected), the preservation property applies to the surrounding behavior — timeouts, headers, logging, error propagation, and response parsing must remain unchanged.
