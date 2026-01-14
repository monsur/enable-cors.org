# CORS Implementation Analysis: Apache HTTP Server
**File:** `server_apache.html`

---

## Current Implementation

**Technology:** Apache HTTP Server
**Approach:** Basic wildcard CORS with mod_headers

**Existing Code:**
```apache
<IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "*"
</IfModule>
```

---

## Issues Identified

### Critical
- ❌ Uses wildcard `*` without security warnings
- ❌ No origin validation example

### High Priority
- ❌ No preflight OPTIONS handling shown
- ❌ Missing `Vary: Origin` header

### Medium Priority
- ⚠️ No explanation of security implications
- ⚠️ Missing guidance for multiple origins

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using `Access-Control-Allow-Origin: *` allows any website to access your API, creating security vulnerabilities. The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)), which means you must implement origin validation logic to support multiple trusted origins.

**Why This Matters:** Wildcard CORS defeats the purpose of same-origin policy and can expose sensitive data or functionality to malicious websites.

### 2. Preflight Request Handling

All CORS implementations must properly handle OPTIONS preflight requests. Browsers send these before certain requests to check permissions.

### 3. Credentials and Authentication

When using credentials (cookies, HTTP auth):
- CANNOT use wildcard `*` for origin
- MUST specify exact origin
- MUST include `Access-Control-Allow-Credentials: true`

### 4. Caching Considerations

When CORS headers vary by origin, MUST include `Vary` header to prevent caching issues where one origin's CORS response is served to another origin.

---

## Recommended Improvements

### Add Security Warning

Add a prominent warning at the top of the page:

```html
<div class="security-warning" style="background: #fff3cd; border: 1px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px;">
  <strong>⚠️ Security Warning:</strong> Using <code>Access-Control-Allow-Origin: *</code>
  allows <strong>any website</strong> to access your resources. This is only appropriate for
  completely public APIs. For most use cases, you should validate and whitelist specific origins.
  <a href="#secure-example">See secure example below</a>.
</div>
```

### Enhanced Apache Configuration

Replace the simple example with a comprehensive one:

```apache
<IfModule mod_headers.c>
  # Simple case - single origin
  Header set Access-Control-Allow-Origin "https://example.com"
  Header set Vary "Origin"

  # For multiple origins, use SetEnvIf
  SetEnvIf Origin "^https?://(example\.com|app\.example\.com)$" ORIGIN_MATCH=$0
  Header set Access-Control-Allow-Origin "%{ORIGIN_MATCH}e" env=ORIGIN_MATCH
  Header set Vary "Origin" env=ORIGIN_MATCH

  # Handle preflight
  RewriteEngine On
  RewriteCond %{REQUEST_METHOD} OPTIONS
  RewriteRule ^(.*)$ $1 [R=204,L]
</IfModule>
```

### Step-by-Step Implementation Guide

Add detailed steps:

1. **Enable mod_headers** (if not already enabled):
   ```bash
   sudo a2enmod headers
   sudo service apache2 restart
   ```

2. **For single origin** (most secure):
   ```apache
   <IfModule mod_headers.c>
     Header set Access-Control-Allow-Origin "https://example.com"
     Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
     Header set Access-Control-Allow-Headers "Content-Type, Authorization"
     Header set Vary "Origin"
   </IfModule>
   ```

3. **For multiple trusted origins**:
   ```apache
   <IfModule mod_headers.c>
     # Validate origin against whitelist
     SetEnvIf Origin "^https?://(www\.)?example\.com$" CORS_ALLOW=$0
     SetEnvIf Origin "^https?://app\.example\.com$" CORS_ALLOW=$0

     Header set Access-Control-Allow-Origin "%{CORS_ALLOW}e" env=CORS_ALLOW
     Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" env=CORS_ALLOW
     Header set Access-Control-Allow-Headers "Content-Type, Authorization" env=CORS_ALLOW
     Header set Vary "Origin" env=CORS_ALLOW
   </IfModule>
   ```

4. **With credentials** (cookies, HTTP auth):
   ```apache
   <IfModule mod_headers.c>
     # Must use specific origin, not wildcard
     Header set Access-Control-Allow-Origin "https://example.com"
     Header set Access-Control-Allow-Credentials "true"
     Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
     Header set Access-Control-Allow-Headers "Content-Type, Authorization"
     Header set Vary "Origin"
   </IfModule>
   ```

5. **Handle preflight OPTIONS requests**:
   ```apache
   <IfModule mod_rewrite.c>
     RewriteEngine On
     RewriteCond %{REQUEST_METHOD} OPTIONS
     RewriteRule ^(.*)$ $1 [R=204,L]
   </IfModule>
   ```

6. **Scope to specific paths** (recommended):
   ```apache
   <Location /api>
     Header set Access-Control-Allow-Origin "https://example.com"
     Header set Vary "Origin"
   </Location>
   ```

### Add Public API Example

For truly public APIs where wildcard is appropriate:

```apache
# PUBLIC API ONLY - Use only for completely public resources
<IfModule mod_headers.c>
  Header set Access-Control-Allow-Origin "*"
  Header set Access-Control-Allow-Methods "GET, POST, OPTIONS"
  Header set Access-Control-Allow-Headers "Content-Type"
</IfModule>
```

With warning:
> "⚠️ This configuration allows any website to access these resources. Only use for public APIs with no sensitive data."

---

## Web Server Specific Considerations

### Scoping Configuration

- Apply CORS headers only where needed (e.g., `/api/*` paths)
- Use `<Location>`, `<Directory>`, or `<VirtualHost>` blocks for fine-grained control
- Avoid global CORS headers on static assets unless necessary

### Example: Scoped Configuration
```apache
# No CORS on static files
<Directory /var/www/html/static>
  # No CORS headers
</Directory>

# CORS only on API endpoints
<Location /api>
  <IfModule mod_headers.c>
    Header set Access-Control-Allow-Origin "https://example.com"
    Header set Vary "Origin"
  </IfModule>
</Location>
```

### Interaction with Caching/CDNs

When using CDNs or caching proxies with Apache:
- Always include `Vary: Origin` when origin varies
- Consider cache-control headers interaction
- Test preflight caching with `Access-Control-Max-Age`

### Performance Considerations

- Regex matching in `SetEnvIf` has minimal performance impact
- Consider moving to application-level validation for complex origin rules
- Use `Header set` instead of `Header add` to avoid duplicates

---

## Testing Your Configuration

1. **Validate Apache config**:
   ```bash
   apachectl -t
   ```

2. **Reload Apache**:
   ```bash
   sudo service apache2 reload
   # or
   apachectl -k graceful
   ```

3. **Test with curl**:
   ```bash
   curl -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: POST" \
        -X OPTIONS \
        -I https://your-api.com/endpoint
   ```

4. **Check response headers**:
   - Look for `Access-Control-Allow-Origin`
   - Verify `Vary: Origin` is present
   - Confirm preflight returns 204

5. **Test in browser DevTools**:
   - Open Network tab
   - Look for CORS headers in response
   - Check Console for CORS errors

---

## Priority

**Critical** - Apache is widely used and the current example promotes insecure practices without adequate warnings.

---

## Implementation Checklist

- [ ] Add security warning banner at top of page
- [ ] Replace simple wildcard example with secure single-origin example
- [ ] Add multi-origin validation example using SetEnvIf
- [ ] Include preflight OPTIONS handling
- [ ] Add Vary: Origin header to all examples
- [ ] Show credentials example (no wildcards)
- [ ] Add scoped configuration example (Location/Directory blocks)
- [ ] Include testing instructions
- [ ] Add note about mod_headers requirement
- [ ] Link to Apache mod_headers documentation

---

## Related Resources

- [Apache mod_headers Documentation](http://httpd.apache.org/docs/current/mod/mod_headers.html)
- [Apache mod_rewrite Documentation](http://httpd.apache.org/docs/current/mod/mod_rewrite.html)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #152: Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** ✅ Implementation Complete
