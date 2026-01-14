# CORS Implementation Analysis: PHP

**File Reference:** `/server_php.html`
**Technology:** PHP (Language-level CORS)
**Analysis Date:** January 2025
**Status:** Critical Priority - Extremely Minimal Documentation

---

## Current Implementation

The current PHP documentation provides only a single-line example:

### Current Code Example

```php
<?php
header("Access-Control-Allow-Origin: *");
```

**Note included:** Must be called before any output is sent.

**Strengths:**
- Simple, easy to understand
- Shows PHP `header()` function usage
- Includes important note about output buffering

---

## Issues Identified

### Critical Priority

**C1. Extremely Minimal Example**
- Only shows the most basic case
- No real-world implementation
- Missing all other required headers
- **Impact:** Users will have incomplete, non-functional CORS implementations
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152)

**C2. No Preflight OPTIONS Handling**
- Doesn't show how to handle OPTIONS requests
- Required for POST/PUT/DELETE with custom headers
- **Impact:** Complex CORS requests will completely fail
- Most common PHP CORS issue

**C3. No Origin Validation**
- Only shows wildcard `*`
- No example of validating origins
- No security warnings
- **Impact:** All PHP implementations will be insecure by default

### High Priority

**H1. Missing Complete Example**
- No production-ready code
- Doesn't show how to structure CORS in real applications
- No error handling
- **Impact:** Users must figure out implementation details themselves

**H2. No Vary Header**
- Missing `Vary: Origin` header
- **Impact:** Caching issues when responses vary by origin

**H3. No Framework Integration**
- Doesn't mention Laravel, Symfony, or other frameworks
- These have better CORS handling
- **Impact:** Framework users may use wrong approach

### Medium Priority

**M1. Output Buffering Not Explained**
- Note about "before any output" is brief
- Doesn't explain common causes (whitespace, BOM)
- No troubleshooting guidance
- **Impact:** "Headers already sent" errors are common

**M2. No Credentials Configuration**
- Doesn't show `Access-Control-Allow-Credentials`
- No example for authenticated APIs
- **Impact:** Cookie-based authentication won't work

**M3. Missing Security Context**
- No explanation of CORS security model
- Doesn't explain when to use CORS
- **Impact:** Misuse and security vulnerabilities

### Low Priority

**L1. No Modern PHP Features**
- Could show namespaces, classes, or modern patterns
- Procedural approach only
- **Impact:** Doesn't reflect modern PHP development

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). You must validate the origin and echo it back if allowed.

**Secure Approach:**
```php
<?php
$allowedOrigins = [
    'https://example.com',
    'https://app.example.com'
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

if (in_array($origin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}
```

### 2. Preflight Request Handling
OPTIONS requests must be handled before your application logic:

```php
<?php
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type, Authorization");
    header("Access-Control-Max-Age: 86400");
    http_response_code(204);
    exit;
}
```

### 3. Credentials and Authentication
When using credentials:
- Cannot use wildcard
- Must set `Access-Control-Allow-Credentials: true`

```php
<?php
header("Access-Control-Allow-Origin: https://example.com");
header("Access-Control-Allow-Credentials: true");
header("Vary: Origin");
```

### 4. Caching Considerations (Vary Header)
Always include when origin affects response:

```php
<?php
header("Vary: Origin");
```

---

## Recommended Improvements

### Complete Production-Ready Example

```php
<?php
/**
 * Enhanced PHP CORS implementation
 * Place at the top of your PHP script before any output
 */

// List of allowed origins
$allowedOrigins = [
    'https://example.com',
    'https://app.example.com',
    'https://admin.example.com'
];

// Get the origin of the request
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// Validate origin against whitelist
if (in_array($origin, $allowedOrigins, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");

    // Allow credentials (cookies, HTTP auth)
    header("Access-Control-Allow-Credentials: true");
}

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // Tell client what methods are allowed
    header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

    // Tell client what headers are allowed
    header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

    // Cache preflight response for 24 hours
    header("Access-Control-Max-Age: 86400");

    // Return 204 No Content
    http_response_code(204);
    exit;
}

// Your application code continues here
header("Content-Type: application/json");
echo json_encode([
    'status' => 'success',
    'message' => 'CORS enabled',
    'data' => []
]);
?>
```

### Reusable CORS Function

```php
<?php
/**
 * Enable CORS for the current request
 *
 * @param array $allowedOrigins List of allowed origins
 * @param bool $allowCredentials Whether to allow credentials
 * @return bool True if origin is allowed, false otherwise
 */
function enableCORS(array $allowedOrigins, bool $allowCredentials = true): bool {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

    // Check if origin is allowed
    if (!in_array($origin, $allowedOrigins, true)) {
        return false;
    }

    // Set CORS headers
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");

    if ($allowCredentials) {
        header("Access-Control-Allow-Credentials: true");
    }

    // Handle preflight
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
        header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
        header("Access-Control-Max-Age: 86400");
        http_response_code(204);
        exit;
    }

    return true;
}

// Usage
$allowedOrigins = ['https://example.com', 'https://app.example.com'];

if (!enableCORS($allowedOrigins)) {
    http_response_code(403);
    echo json_encode(['error' => 'Origin not allowed']);
    exit;
}

// Your API logic here
echo json_encode(['message' => 'CORS enabled and validated']);
?>
```

### CORS Class (Modern PHP)

```php
<?php
namespace App\Http;

class CORS {
    private array $allowedOrigins;
    private bool $allowCredentials;

    public function __construct(array $allowedOrigins, bool $allowCredentials = true) {
        $this->allowedOrigins = $allowedOrigins;
        $this->allowCredentials = $allowCredentials;
    }

    public function handle(): bool {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

        // Validate origin
        if (!in_array($origin, $this->allowedOrigins, true)) {
            return false;
        }

        // Set CORS headers
        header("Access-Control-Allow-Origin: $origin");
        header("Vary: Origin");

        if ($this->allowCredentials) {
            header("Access-Control-Allow-Credentials: true");
        }

        // Handle preflight
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            $this->handlePreflight();
            exit;
        }

        return true;
    }

    private function handlePreflight(): void {
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
        header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
        header("Access-Control-Max-Age: 86400");
        http_response_code(204);
    }
}

// Usage
$cors = new CORS([
    'https://example.com',
    'https://app.example.com'
]);

if (!$cors->handle()) {
    http_response_code(403);
    die(json_encode(['error' => 'Origin not allowed']));
}

// Your application logic
?>
```

### Framework Integration Notes

Add section for popular frameworks:

```markdown
## Framework-Specific Solutions

### Laravel
Laravel has built-in CORS support via middleware:

composer require fruitcake/laravel-cors

// In config/cors.php
return [
    'paths' => ['api/*'],
    'allowed_origins' => ['https://example.com'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE'],
    'allowed_headers' => ['Content-Type', 'Authorization'],
    'supports_credentials' => true,
    'max_age' => 86400,
];

### Symfony
Use NelmioCorsBundle:

composer require nelmio/cors-bundle

// In config/packages/nelmio_cors.yaml
nelmio_cors:
    paths:
        '^/api':
            allow_origin: ['https://example.com']
            allow_methods: ['GET', 'POST', 'PUT', 'DELETE']
            allow_headers: ['Content-Type', 'Authorization']
            max_age: 86400

### Slim Framework
Use CORS middleware:

$app->add(function ($request, $handler) {
    $response = $handler->handle($request);
    return $response
        ->withHeader('Access-Control-Allow-Origin', 'https://example.com')
        ->withHeader('Vary', 'Origin');
});
```

### Security Warning to Add

```html
⚠️ Security Warning: The simple Access-Control-Allow-Origin: * example is only
suitable for completely public APIs. For most applications, validate the origin
as shown in the enhanced examples below. Never use wildcards with authenticated
or sensitive APIs.
```

---

## Technology-Specific Considerations

### Output Buffering

PHP requires headers before any output:

```php
<?php
// WRONG - whitespace before <?php tag
// Output has already started!
header("Access-Control-Allow-Origin: *"); // Error!

// CORRECT - no output before headers
header("Access-Control-Allow-Origin: https://example.com");
echo "Content";
?>
```

**Common Causes of "Headers Already Sent" Error:**
- Whitespace before `<?php` tag
- Byte Order Mark (BOM) in UTF-8 files
- Echo/print statements before headers
- Include files with output

**Solutions:**
```php
<?php
// Solution 1: Use output buffering
ob_start();

// Your code...
header("Access-Control-Allow-Origin: https://example.com");

ob_end_flush();

// Solution 2: Set headers in .htaccess (if using Apache)
// See Apache CORS documentation
?>
```

### $_SERVER Variables for CORS

Important superglobal variables:

```php
<?php
// Request origin
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';

// Request method
$method = $_SERVER['REQUEST_METHOD'];

// Requested headers (in preflight)
$requestHeaders = $_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? '';

// Requested method (in preflight)
$requestMethod = $_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'] ?? '';
?>
```

### PHP Version Considerations

- **PHP 7.0+:** Use null coalescing operator (`??`)
- **PHP 7.1+:** Use strict typing (`declare(strict_types=1)`)
- **PHP 7.4+:** Use typed properties
- **PHP 8.0+:** Use named arguments and attributes

### Performance

```php
<?php
// Cache origin validation result
static $originChecked = false;
static $originAllowed = false;

if (!$originChecked) {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    $originAllowed = in_array($origin, $allowedOrigins, true);
    $originChecked = true;
}

if ($originAllowed) {
    header("Access-Control-Allow-Origin: $origin");
}
?>
```

---

## Testing Instructions

### 1. Test with curl

```bash
# Test preflight
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     -v http://your-server.com/api/endpoint.php

# Test actual request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"test":"data"}' \
     -v http://your-server.com/api/endpoint.php
```

### 2. Test in Browser Console

```javascript
// Test CORS request
fetch('http://your-server.com/api/endpoint.php', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include', // If using cookies
  body: JSON.stringify({test: 'data'})
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

### 3. Check PHP Error Log

```bash
# Location varies by system
tail -f /var/log/php-errors.log

# Or check Apache/Nginx error logs
tail -f /var/log/apache2/error.log
tail -f /var/log/nginx/error.log
```

### 4. Test Origin Validation

```bash
# Should work - allowed origin
curl -H "Origin: https://example.com" \
     -v http://your-server.com/api/endpoint.php

# Should NOT have CORS headers - disallowed origin
curl -H "Origin: https://evil.com" \
     -v http://your-server.com/api/endpoint.php
```

### 5. Common Issues

**"Headers already sent" error:**
- Check for output before header() calls
- Remove whitespace before `<?php`
- Check for BOM in UTF-8 files
- Use output buffering as workaround

**OPTIONS request returns 404:**
- Server may not be routing OPTIONS requests
- Add .htaccess rule or Nginx configuration
- Handle OPTIONS in your PHP script

**Credentials not working:**
- Verify `Access-Control-Allow-Credentials: true`
- Verify origin is not wildcard
- Check browser sends `credentials: 'include'`

---

## Priority

**CRITICAL PRIORITY**

**Justification:**
- PHP is one of the most widely used server-side languages
- Current documentation is extremely minimal (single line)
- Missing all essential CORS components (preflight, validation)
- High impact on security - users will create vulnerable implementations
- Easy to improve with comprehensive examples

**Impact:** CRITICAL - Millions of PHP sites potentially affected

**Effort:** Medium - Need comprehensive examples but PHP is straightforward

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Add comprehensive production-ready example
- [ ] Show preflight OPTIONS handling
- [ ] Add origin validation example
- [ ] Include prominent security warning
- [ ] Link to [#152](https://github.com/monsur/enable-cors.org/issues/152)

### Short-term Actions (High Priority)
- [ ] Add reusable CORS function
- [ ] Show modern PHP class-based approach
- [ ] Include `Vary: Origin` header
- [ ] Document output buffering issues
- [ ] Add framework integration examples (Laravel, Symfony)

### Medium-term Actions
- [ ] Create troubleshooting section
- [ ] Add credentials configuration example
- [ ] Document PHP superglobal variables for CORS
- [ ] Show error handling patterns
- [ ] Add performance considerations

### Long-term Actions
- [ ] Create PHP CORS package/library
- [ ] Add video tutorial
- [ ] Create interactive PHP CORS generator
- [ ] Add examples for PHP-FPM, mod_php differences

---

## Related Resources

### Official Documentation
- [PHP header() Function](https://www.php.net/manual/en/function.header.php)
- [PHP $_SERVER Superglobal](https://www.php.net/manual/en/reserved.variables.server.php)
- [PHP HTTP Response Codes](https://www.php.net/manual/en/function.http-response-code.php)

### Framework CORS Packages
- [Laravel CORS](https://github.com/fruitcake/laravel-cors)
- [NelmioCorsBundle (Symfony)](https://github.com/nelmio/NelmioCorsBundle)
- [Slim CORS Middleware](https://github.com/psr7-sessions/session-middleware)

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Additional Resources
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [PHP The Right Way](https://phptherightway.com/)

### Related enable-cors.org Pages
- [Apache CORS Configuration](server_apache.html) - Often used with PHP
- [Nginx CORS Configuration](server_nginx.html) - Often used with PHP-FPM
- [CGI CORS Configuration](server_cgi.html) - Legacy PHP CGI

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** ✅ Implementation Complete
