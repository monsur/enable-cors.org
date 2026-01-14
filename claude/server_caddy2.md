# CORS Implementation Analysis: Caddy v2

**File Reference:** `/server_caddy2.html`
**Technology:** Caddy Server version 2 (Current)
**Analysis Date:** January 2025
**Status:** High Priority - Security Updates Needed

---

## Current Implementation

The current Caddy v2 documentation provides a simple header-based approach:

### Current Code Example

```caddyfile
sitename.com {
  file_server
  encode zstd gzip

  header {
    Access-Control-Allow-Headers *
    Access-Control-Allow-Methods *
    Access-Control-Allow-Origin *
  }
  @options {
    method OPTIONS
  }
  respond @options 204
}
```

**Strengths:**
- Shows Caddy v2 syntax (addresses [#153](https://github.com/monsur/enable-cors.org/issues/153))
- Includes preflight OPTIONS handling
- Clean, modern Caddyfile format
- Distinguishes from v1 syntax

---

## Issues Identified

### Critical Priority

**C1. Triple Wildcard Configuration**
- Uses `*` for ALL three headers: Origin, Methods, Headers
- Extremely permissive - allows everything from everywhere
- No security warning provided
- **Impact:** Maximum security risk, any website can make any request
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152)

**C2. No Origin Validation**
- No example showing how to validate specific origins
- Wildcard-only approach encourages insecure defaults
- **Impact:** Users don't know how to secure configuration
- **Related Issue:** [#146](https://github.com/monsur/enable-cors.org/issues/146)

### High Priority

**H1. Missing Vary Header**
- No `Vary: Origin` header in example
- Critical when origin varies in response
- **Impact:** Caching issues, security problems with CDNs
- **Related Issue:** [#164](https://github.com/monsur/enable-cors.org/issues/164)

**H2. Incomplete Preflight Handling**
- OPTIONS handler is good, but missing headers in preflight response
- No `Access-Control-Max-Age` for preflight caching
- **Impact:** More preflight requests than necessary, no cache optimization

**H3. No Explanation of Wildcards**
- Doesn't explain what `*` means for each header type
- `Access-Control-Allow-Headers: *` has different behavior than origin wildcard
- **Impact:** Confusion about wildcard behavior

### Medium Priority

**M1. No Credentials Handling**
- Doesn't show `Access-Control-Allow-Credentials`
- No example for authenticated APIs
- **Impact:** Users with authenticated APIs will struggle

**M2. Missing Context**
- No explanation of when to use this configuration
- Doesn't distinguish between public and private APIs
- No production guidance
- **Impact:** Inappropriate use of wildcard configuration

**M3. No Alternate Approaches**
- Caddy v2 has no built-in cors middleware
- Could use reverse_proxy with header manipulation
- Could use Caddy modules for more complex scenarios
- **Impact:** Users may not know about alternative approaches

### Low Priority

**L1. Limited Error Handling**
- No guidance on troubleshooting CORS issues
- Missing common error patterns
- **Impact:** Difficult to debug when things don't work

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). For multiple origins, you must implement origin validation.

**Secure Approach:**
```caddyfile
sitename.com {
  # Use matchers to validate origin
  @cors_origin {
    header Origin https://example.com
  }

  header @cors_origin {
    Access-Control-Allow-Origin "{http.request.header.Origin}"
    Vary "Origin"
  }
}
```

### 2. Preflight Request Handling
OPTIONS requests need proper headers for preflight:

```caddyfile
@cors_preflight {
  method OPTIONS
}

header @cors_preflight {
  Access-Control-Allow-Origin "https://example.com"
  Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
  Access-Control-Allow-Headers "Content-Type, Authorization"
  Access-Control-Max-Age "86400"
  Vary "Origin"
}

respond @cors_preflight 204
```

### 3. Credentials and Authentication
When using credentials:
- Cannot use wildcard for origin
- Must set `Access-Control-Allow-Credentials: true`
- Origin must match exactly

```caddyfile
header {
  Access-Control-Allow-Origin "https://example.com"
  Access-Control-Allow-Credentials "true"
  Vary "Origin"
}
```

### 4. Caching Considerations (Vary Header)
Always include `Vary: Origin` when origin affects response:

```caddyfile
header {
  Vary "Origin"
}
```

---

## Recommended Improvements

### Secure Configuration for Single Origin

```caddyfile
sitename.com {
  # Secure configuration for single trusted origin
  file_server
  encode zstd gzip

  # Handle preflight requests
  @cors_preflight {
    method OPTIONS
  }

  header @cors_preflight {
    Access-Control-Allow-Origin "https://example.com"
    Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Access-Control-Allow-Headers "Content-Type, Authorization"
    Access-Control-Max-Age "86400"
    Vary "Origin"
  }

  respond @cors_preflight 204

  # For actual requests
  header {
    Access-Control-Allow-Origin "https://example.com"
    Vary "Origin"
  }
}
```

### Secure Configuration for Multiple Origins

```caddyfile
sitename.com {
  # Validate multiple origins using regex
  @cors_origin_match {
    header_regexp origin Origin ^https?://(www\.)?(example\.com|app\.example\.com)$
  }

  # Preflight for matched origins
  @cors_preflight {
    method OPTIONS
  }

  header @cors_preflight {
    Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Access-Control-Allow-Headers "Content-Type, Authorization"
    Access-Control-Max-Age "86400"
  }

  header @cors_origin_match {
    Access-Control-Allow-Origin "{http.request.header.Origin}"
    Vary "Origin"
  }

  respond @cors_preflight 204

  # Your backend
  reverse_proxy localhost:8080
}
```

### Configuration with Credentials

```caddyfile
api.example.com {
  # CORS with credentials for authenticated API
  @cors_allowed {
    header Origin https://example.com
  }

  @cors_preflight {
    method OPTIONS
  }

  header @cors_preflight {
    Access-Control-Allow-Origin "https://example.com"
    Access-Control-Allow-Methods "GET, POST, PUT, DELETE"
    Access-Control-Allow-Headers "Content-Type, Authorization"
    Access-Control-Allow-Credentials "true"
    Access-Control-Max-Age "86400"
    Vary "Origin"
  }

  respond @cors_preflight 204

  header @cors_allowed {
    Access-Control-Allow-Origin "https://example.com"
    Access-Control-Allow-Credentials "true"
    Vary "Origin"
  }

  # API backend
  reverse_proxy localhost:3000
}
```

### Path-Specific CORS

```caddyfile
example.com {
  # Public API - open CORS
  handle /api/public/* {
    header {
      Access-Control-Allow-Origin "*"
    }
    reverse_proxy localhost:8080
  }

  # Private API - restricted CORS
  handle /api/private/* {
    @cors_origin {
      header Origin https://example.com
    }

    header @cors_origin {
      Access-Control-Allow-Origin "https://example.com"
      Access-Control-Allow-Credentials "true"
      Vary "Origin"
    }

    reverse_proxy localhost:8080
  }

  # Static files - no CORS
  handle {
    file_server
  }
}
```

### Security Warning to Add

```html
⚠️ Security Warning: The wildcard examples (Access-Control-Allow-*: *) allow
ANY website to access your resources with ANY method and ANY headers. Only use
wildcards for completely public APIs. For production applications, always specify
allowed origins, methods, and headers explicitly.
```

---

## Technology-Specific Considerations

### Caddy v2 Architecture

**No Built-in CORS Middleware:**
- Caddy v2 removed the dedicated cors middleware
- Must use `header` directive and matchers
- More flexible but requires more configuration
- Can implement custom logic with Caddy modules

### Matcher System

Caddy v2's matcher system is powerful for CORS:

```caddyfile
# Match by origin
@origin_match {
  header Origin https://example.com
}

# Match by path and origin
@api_cors {
  path /api/*
  header Origin https://example.com
}

# Match by regex
@origin_regex {
  header_regexp origin Origin ^https://.*\.example\.com$
}
```

### Header Placeholders

Use placeholders to echo validated origins:

```caddyfile
header {
  Access-Control-Allow-Origin "{http.request.header.Origin}"
}
```

### Performance Optimization

Cache preflight responses:
```caddyfile
header @cors_preflight {
  Access-Control-Max-Age "86400"  # 24 hours
  Cache-Control "public, max-age=86400"
}
```

### Integration with reverse_proxy

```caddyfile
sitename.com {
  reverse_proxy localhost:8080 {
    # Let backend handle CORS
    header_up Origin {http.request.header.Origin}
  }

  # Or handle at Caddy level
  header {
    Access-Control-Allow-Origin "https://example.com"
  }
}
```

---

## Testing Instructions

### 1. Test Preflight Request

```bash
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type, Authorization" \
     -X OPTIONS \
     -v https://your-site.com/api/endpoint

# Expected response:
# HTTP/1.1 204 No Content
# Access-Control-Allow-Origin: https://example.com
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
# Access-Control-Allow-Headers: Content-Type, Authorization
# Access-Control-Max-Age: 86400
# Vary: Origin
```

### 2. Test Actual CORS Request

```bash
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"test":"data"}' \
     -v https://your-site.com/api/endpoint

# Should include:
# Access-Control-Allow-Origin: https://example.com
# Vary: Origin
```

### 3. Test Origin Validation

```bash
# Test with allowed origin
curl -H "Origin: https://example.com" \
     -v https://your-site.com/

# Test with disallowed origin
curl -H "Origin: https://evil.com" \
     -v https://your-site.com/

# Second request should NOT have Access-Control-Allow-Origin header
```

### 4. Browser Testing

Open browser console:
```javascript
// Test CORS request
fetch('https://your-site.com/api/data', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({test: 'data'})
})
.then(r => r.json())
.then(console.log)
.catch(console.error);

// Check response headers
fetch('https://your-site.com/api/data')
  .then(r => {
    console.log('CORS headers:');
    console.log('Allow-Origin:', r.headers.get('Access-Control-Allow-Origin'));
    console.log('Allow-Credentials:', r.headers.get('Access-Control-Allow-Credentials'));
    console.log('Vary:', r.headers.get('Vary'));
  });
```

### 5. Caddy Logs

Check Caddy logs for issues:
```bash
# View Caddy logs
caddy logs

# Or with journalctl (if using systemd)
journalctl -u caddy -f

# Enable debug logging
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile --debug
```

### 6. Common Issues

**CORS headers not appearing:**
- Check matcher conditions are met
- Verify Caddyfile syntax with `caddy validate`
- Ensure Caddy has been reloaded after config changes

**Wildcard not working with credentials:**
- Cannot use `*` with credentials
- Must specify exact origin
- Browsers enforce this strictly

**Preflight failing:**
- Verify OPTIONS returns 204
- Check all headers are in Allow-Headers
- Confirm method is in Allow-Methods

---

## Priority

**HIGH PRIORITY**

**Justification:**
- Caddy v2 is current version (active development)
- Current example uses triple wildcard (maximum insecurity)
- Missing critical security guidance
- No origin validation examples
- Growing user base needs better documentation

**Impact:** High - Caddy v2 is increasingly popular, especially for modern applications

**Effort:** Medium - Requires comprehensive examples and explanation

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Add prominent security warning about triple wildcard
- [ ] Show secure single-origin example first
- [ ] Add origin validation for multiple origins
- [ ] Include `Vary: Origin` in all examples
- [ ] Link to [#152](https://github.com/monsur/enable-cors.org/issues/152)

### Short-term Actions (High Priority)
- [ ] Add `Access-Control-Max-Age` to preflight examples
- [ ] Show credentials configuration
- [ ] Document matcher system for origin validation
- [ ] Add path-specific CORS examples
- [ ] Include production vs development configurations

### Medium-term Actions
- [ ] Create troubleshooting section
- [ ] Add integration examples with reverse_proxy
- [ ] Document header placeholders
- [ ] Show regex-based origin matching
- [ ] Add performance optimization tips

### Long-term Actions
- [ ] Create Caddy v2 CORS module (external project)
- [ ] Add interactive Caddyfile generator
- [ ] Create video tutorial
- [ ] Document advanced patterns (API gateway, microservices)

---

## Related Resources

### Official Documentation
- [Caddy v2 Documentation](https://caddyserver.com/docs/)
- [Caddy header Directive](https://caddyserver.com/docs/caddyfile/directives/header)
- [Caddy Matchers](https://caddyserver.com/docs/caddyfile/matchers)
- [Caddy Placeholders](https://caddyserver.com/docs/caddyfile/concepts#placeholders)

### Related GitHub Issues
- [#153 - Caddy instructions don't work with v2](https://github.com/monsur/enable-cors.org/issues/153) - RESOLVED
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)
- [#164 - Integration with modern security headers](https://github.com/monsur/enable-cors.org/issues/164)

### Additional Resources
- [Caddy Community Forums](https://caddy.community/)
- [Caddy GitHub Repository](https://github.com/caddyserver/caddy)
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

### Related enable-cors.org Pages
- [Caddy v1 CORS Configuration](server_caddy.html) - Legacy version
- [Nginx CORS Configuration](server_nginx.html) - Similar approach
- [Apache CORS Configuration](server_apache.html)

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
