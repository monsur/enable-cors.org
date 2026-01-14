# CORS Implementation Analysis: Nginx
**File:** `server_nginx.html`

---

## Current Implementation

**Technology:** Nginx
**Approach:** Two examples - wildcard and origin-specific with map directive

**Existing Code Patterns:**
1. Wide-open wildcard CORS
2. Origin-specified CORS with map directive validation

---

## Strengths

✅ Includes `Vary: Origin` header (best practice)
✅ Proper preflight OPTIONS handling
✅ Shows both simple and advanced patterns
✅ Uses map directive for origin validation

---

## Issues Identified

### High Priority
- ⚠️ Wildcard example lacks prominent security warnings
- ⚠️ Complex `map` directive may confuse beginners
- ⚠️ Missing explanation of why `Vary: Origin` is important

### Medium Priority
- Missing middle-ground example between wildcard and map directive
- Could benefit from simpler origin validation example

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using `Access-Control-Allow-Origin: *` allows any website to access your API, creating security vulnerabilities. The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)).

**Why This Matters:** Wildcard CORS defeats the purpose of same-origin policy and can expose sensitive data or functionality to malicious websites.

### 2. The Vary Header

**Critical for Nginx:** The `Vary: Origin` header is essential when your CORS headers change based on the origin. It prevents cache poisoning where one origin receives another origin's cached response.

### 3. Preflight Request Handling

Nginx must handle OPTIONS preflight requests properly with correct status code (204) and appropriate headers.

### 4. Credentials and Authentication

When using credentials (cookies, HTTP auth):
- CANNOT use wildcard `*` for origin
- MUST specify exact origin
- MUST include `Access-Control-Allow-Credentials: true`

---

## Recommended Improvements

### Add Security Warning

Move security warning to the top before code examples:

```html
<div class="security-warning" style="background: #fff3cd; border: 1px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px;">
  <strong>⚠️ Security Warning:</strong> The wildcard <code>Access-Control-Allow-Origin: *</code>
  allows <strong>any website</strong> to access your resources. This is only appropriate for
  completely public APIs. For most use cases, validate and whitelist specific origins.
</div>
```

### Add Explanation of Vary Header

```html
<div class="info-box">
  <strong>Why Vary: Origin?</strong> The <code>Vary: Origin</code> header is critical when your CORS headers
  change based on the origin. It prevents cache poisoning where one origin receives another origin's
  cached response. Always include it when using origin validation.
</div>
```

### Improved Example Structure

**1. Simple Single Origin (Recommended for Most Use Cases)**

```nginx
location /api {
    # Single trusted origin
    add_header 'Access-Control-Allow-Origin' 'https://example.com' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Vary' 'Origin' always;

    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 86400;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }
}
```

**2. Simple Multi-Origin Validation (Good Balance)**

```nginx
location /api {
    set $cors_origin "";

    # Validate against allowed origins
    if ($http_origin ~* (https?://(www\.)?example\.com|https?://app\.example\.com)) {
        set $cors_origin $http_origin;
    }

    # Only set CORS headers if origin is allowed
    add_header 'Vary' 'Origin' always;
    add_header 'Access-Control-Allow-Origin' $cors_origin always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;

    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 86400;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }
}
```

**3. Advanced: Map Directive (For Complex Rules)**

In the `http {}` block (typically in nginx.conf):

```nginx
http {
    # Map for CORS origin validation
    map '$request_method $http_origin' $allow_cors {
        '~^OPTIONS https://(example\.com|app\.example\.com|api\.example\.com)$'    OPTIONS;
        '~^(GET|POST|PUT|DELETE) https://(example\.com|app\.example\.com|api\.example\.com)$' GET|POST|PUT|DELETE;
        default 0;
    }

    # ... rest of http block
}
```

In your server/location block:

```nginx
location /api {
    if ($allow_cors = OPTIONS) {
        add_header 'Vary' 'Origin' always;
        add_header 'Access-Control-Allow-Origin' $http_origin;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
        add_header 'Access-Control-Max-Age' 86400;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    if ($allow_cors = GET|POST|PUT|DELETE) {
        add_header 'Vary' 'Origin' always;
        add_header 'Access-Control-Allow-Origin' $http_origin always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
    }

    # Your proxy_pass or other directives
}
```

**4. With Credentials**

```nginx
location /api {
    # Must use specific origin, not wildcard
    add_header 'Access-Control-Allow-Origin' 'https://example.com' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
    add_header 'Vary' 'Origin' always;

    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 86400;
        return 204;
    }
}
```

**5. Public API (Wildcard)**

```nginx
# PUBLIC API ONLY - Use only for completely public resources
location /public-api {
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type' always;

    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Max-Age' 86400;
        return 204;
    }
}
```

---

## Web Server Specific Considerations

### Nginx Configuration Best Practices

#### 1. The "always" Parameter
Use `always` parameter with `add_header` to ensure headers are added even for error responses:
```nginx
add_header 'Access-Control-Allow-Origin' 'https://example.com' always;
```

#### 2. Avoid Nested If Statements
Nginx's if directive has limitations. Avoid nested ifs when possible:
```nginx
# AVOID
if ($request_method = 'OPTIONS') {
    if ($http_origin ~* example.com) {
        # nested if - problematic
    }
}

# BETTER - Use map directive
```

#### 3. Map Directive Placement
The `map` directive must be in the `http {}` block, not in `server {}` or `location {}`:
```nginx
# In nginx.conf or included file
http {
    map $http_origin $cors_allowed {
        https://example.com 1;
        https://app.example.com 1;
        default 0;
    }
}
```

#### 4. Header Inheritance
Be aware that `add_header` directives in child blocks override parent blocks entirely:
```nginx
server {
    add_header X-Server-Header "value";

    location /api {
        # This location block must re-add X-Server-Header if needed
        add_header 'Access-Control-Allow-Origin' 'https://example.com';
        add_header X-Server-Header "value";  # Must repeat!
    }
}
```

### Performance Considerations

- Regex matching in `if` statements is fast but use map directives for complex rules
- The `always` parameter has minimal performance impact
- Consider application-level validation for very complex origin rules

### Scoping Configuration

```nginx
# No CORS on static files
location /static {
    # No CORS headers
    root /var/www/static;
}

# CORS only on API endpoints
location /api {
    # CORS configuration here
    proxy_pass http://backend;
}
```

### Interaction with Caching/CDNs

When using Nginx with caching or CDNs:
- **Always** include `Vary: Origin` when origin varies
- Test cache behavior with different origins
- Consider `proxy_cache_key` if using Nginx caching:
  ```nginx
  proxy_cache_key "$scheme$request_method$host$request_uri$http_origin";
  ```

---

## Testing Your Configuration

1. **Test Nginx config syntax**:
   ```bash
   nginx -t
   ```

2. **Reload Nginx**:
   ```bash
   nginx -s reload
   # or
   sudo systemctl reload nginx
   ```

3. **Test with curl**:
   ```bash
   # Test actual request
   curl -H "Origin: https://example.com" \
        -I https://your-api.com/api/endpoint

   # Test preflight
   curl -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: POST" \
        -X OPTIONS \
        -I https://your-api.com/api/endpoint
   ```

4. **Verify headers**:
   - `Access-Control-Allow-Origin` matches request origin
   - `Vary: Origin` is present
   - Preflight returns 204 No Content
   - `Access-Control-Max-Age` is set

5. **Test invalid origin**:
   ```bash
   curl -H "Origin: https://evil.com" \
        -I https://your-api.com/api/endpoint
   ```
   Should NOT return CORS headers

---

## Priority

**Medium** - Nginx examples are mostly good but need better documentation and security warnings on wildcard example.

---

## Implementation Checklist

- [ ] Add security warning before wildcard example
- [ ] Add explanation of `Vary: Origin` header importance
- [ ] Include simple multi-origin example (middle ground)
- [ ] Explain map directive placement (http block)
- [ ] Add credentials example
- [ ] Document the `always` parameter
- [ ] Show scoped configuration example
- [ ] Add testing instructions
- [ ] Warn about nested if statements
- [ ] Document header inheritance behavior

---

## Related Resources

- [Nginx HTTP Headers Module](https://nginx.org/en/docs/http/ngx_http_headers_module.html)
- [Nginx Map Module](https://nginx.org/en/docs/http/ngx_http_map_module.html)
- [Nginx If Is Evil](https://www.nginx.com/resources/wiki/start/topics/depth/ifisevil/)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #152: Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** Ready for implementation
