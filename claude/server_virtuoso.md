# CORS Implementation Analysis: OpenLink Virtuoso
**File:** `server_virtuoso.html`

---

## Current Implementation

**Technology:** OpenLink Virtuoso (Database/Application Server)
**Approach:** GUI configuration and VSP (Virtuoso Server Pages) code

**Two Methods Shown:**
1. GUI configuration through Virtuoso Conductor
2. Programmatic VSP code using `http_request_header()` and `http_header()`

---

## Strengths

✅ Shows both GUI and programmatic approaches
✅ Includes origin validation in code example
✅ Good documentation links
✅ Provides minimum version requirements

---

## Issues Identified

### Medium Priority
- ⚠️ Very niche database/application server
- ⚠️ Minimum version requirements may be outdated
- ⚠️ Code example only validates one origin (no list/array)
- ⚠️ Missing preflight OPTIONS handling in code example

### Low Priority
- VSP syntax may be unfamiliar to most developers
- No modern framework integration examples

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using wildcard `*` in Virtuoso Conductor allows any website to access your resources. The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)).

**Why This Matters:** Virtuoso often serves RDF/linked data and SPARQL endpoints that may contain sensitive information.

### 2. Preflight Request Handling

Virtuoso must handle OPTIONS requests in VSP code to properly support CORS preflight.

### 3. Credentials and Authentication

When using HTTP authentication with Virtuoso:
- CANNOT use wildcard `*` for origin
- MUST specify exact origin
- MUST include appropriate CORS headers for credentials

### 4. SPARQL Endpoint CORS

Special consideration for SPARQL endpoints which are commonly accessed cross-origin.

---

## Recommended Improvements

### Enhanced VSP Implementation

**Multiple Origin Validation with Preflight Handling:**

```vsp
<?vsp
-- Enhanced Virtuoso CORS implementation
DECLARE allowed_origins ANY;
DECLARE request_origin VARCHAR;
DECLARE request_method VARCHAR;
DECLARE i INT;

-- List of allowed origins
allowed_origins := vector(
  'https://example.com',
  'https://app.example.com',
  'https://dashboard.example.com'
);

-- Get request origin and method
request_origin := http_request_header(lines, 'Origin', NULL);
request_method := http_request_header(lines, 'REQUEST_METHOD', NULL);

-- Validate origin against whitelist
FOR (i := 0; i < length(allowed_origins); i := i + 1)
{
  IF (request_origin = allowed_origins[i])
  {
    -- Origin is valid, set CORS headers
    http_header(sprintf('Access-Control-Allow-Origin: %s\r\n', request_origin));
    http_header('Vary: Origin\r\n');
    GOTO origin_valid;
  }
}

-- Origin not valid - reject CORS
RETURN;

origin_valid:
-- Handle preflight OPTIONS request
IF (request_method = 'OPTIONS')
{
  http_header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n');
  http_header('Access-Control-Allow-Headers: Content-Type, Authorization, Accept\r\n');
  http_header('Access-Control-Max-Age: 86400\r\n');
  http_status_set(204);
  RETURN;
}

-- Allow credentials if needed
-- http_header('Access-Control-Allow-Credentials: true\r\n');

-- Your application logic here
http_header('Content-Type: application/json\r\n');
http('{"message": "CORS enabled"}');
?>
```

**Pattern Matching for Subdomains:**

```vsp
<?vsp
DECLARE request_origin VARCHAR;
DECLARE origin_pattern VARCHAR;

request_origin := http_request_header(lines, 'Origin', NULL);

-- Allow all subdomains of example.com
origin_pattern := '^https?://([a-zA-Z0-9-]+\\.)?example\\.com$';

IF (regexp_match(origin_pattern, request_origin) IS NOT NULL)
{
  http_header(sprintf('Access-Control-Allow-Origin: %s\r\n', request_origin));
  http_header('Vary: Origin\r\n');
}
ELSE
{
  -- Origin not allowed
  RETURN;
}

-- Continue with application logic...
?>
```

**SPARQL Endpoint CORS:**

```vsp
<?vsp
-- CORS for SPARQL endpoint
DECLARE request_origin VARCHAR;
DECLARE allowed_origins ANY;

request_origin := http_request_header(lines, 'Origin', NULL);

allowed_origins := vector(
  'https://example.com',
  'https://sparql-client.example.com'
);

-- Validate origin
IF (position(request_origin, allowed_origins) > 0)
{
  http_header(sprintf('Access-Control-Allow-Origin: %s\r\n', request_origin));
  http_header('Vary: Origin\r\n');
  
  -- Handle preflight
  IF (http_request_header(lines, 'REQUEST_METHOD', NULL) = 'OPTIONS')
  {
    http_header('Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n');
    http_header('Access-Control-Allow-Headers: Content-Type, Accept\r\n');
    http_header('Access-Control-Max-Age: 3600\r\n');
    http_status_set(204);
    RETURN;
  }
}

-- Process SPARQL query...
?>
```

**With Credentials:**

```vsp
<?vsp
DECLARE request_origin VARCHAR;

request_origin := http_request_header(lines, 'Origin', NULL);

-- Must use specific origin, not wildcard
IF (request_origin = 'https://example.com')
{
  http_header(sprintf('Access-Control-Allow-Origin: %s\r\n', request_origin));
  http_header('Access-Control-Allow-Credentials: true\r\n');
  http_header('Vary: Origin\r\n');
}

-- Application logic...
?>
```

---

## Virtuoso-Specific Considerations

### 1. Conductor GUI Configuration

For Virtuoso 6.1.3+ or Commercial Edition 06.02.3129+:

1. Navigate to **Virtuoso Conductor** → **Web Application Server** → **Virtual Domains & Directories**
2. Expand the Interface store
3. Click **New Directory**
4. Set CORS options:
   - **Cross-Origin Resource Sharing**: Enter specific origin (e.g., `https://example.com`)
   - **Reject Unintended CORS**: Check to reject non-whitelisted origins
5. Save changes

**Security Note:** Use specific origins, not wildcard `*`.

### 2. Version Requirements

- **VOS 6.1.3+** (Open Source)
- **Commercial 06.02.3129+**

For older versions, use VSP code approach only.

### 3. RDF/Linked Data Considerations

Virtuoso commonly serves:
- RDF data
- SPARQL endpoints
- Linked Open Data

These are frequently accessed cross-origin, making proper CORS configuration critical.

### 4. Performance

VSP code runs on every request. Consider:
- Caching allowed origins list
- Using Conductor GUI configuration when possible (more efficient)
- Limiting regex complexity in pattern matching

### 5. Integration with Applications

```vsp
<?vsp
-- Reusable CORS function
CREATE PROCEDURE check_cors(
  IN request_origin VARCHAR,
  IN allowed_origins ANY)
{
  DECLARE i INT;
  
  FOR (i := 0; i < length(allowed_origins); i := i + 1)
  {
    IF (request_origin = allowed_origins[i])
    {
      http_header(sprintf('Access-Control-Allow-Origin: %s\r\n', request_origin));
      http_header('Vary: Origin\r\n');
      RETURN 1;
    }
  }
  
  RETURN 0;
}

-- Usage in VSP pages
DECLARE origins ANY;
DECLARE request_origin VARCHAR;

origins := vector('https://example.com', 'https://app.example.com');
request_origin := http_request_header(lines, 'Origin', NULL);

IF (check_cors(request_origin, origins) = 0)
{
  http_status_set(403);
  http('{"error": "Origin not allowed"}');
  RETURN;
}

-- Continue with application logic...
?>
```

---

## Testing Your Configuration

### 1. Test with curl

```bash
# Test actual request
curl -H "Origin: https://example.com" \
     http://localhost:8890/sparql \
     -v

# Test preflight
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     http://localhost:8890/sparql \
     -v

# Test SPARQL query with CORS
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/sparql-query" \
     -d "SELECT * WHERE { ?s ?p ?o } LIMIT 10" \
     http://localhost:8890/sparql \
     -v
```

### 2. Test in Virtuoso Conductor

1. Navigate to **Conductor** → **Web Application Server**
2. Test the configured virtual directory
3. Check headers in browser DevTools

### 3. Test SPARQL Endpoint

```javascript
// JavaScript client
fetch('http://localhost:8890/sparql', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/sparql-query',
    'Accept': 'application/sparql-results+json'
  },
  body: 'SELECT * WHERE { ?s ?p ?o } LIMIT 10'
})
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

### 4. Verify Headers

Expected headers:
```
Access-Control-Allow-Origin: https://example.com
Vary: Origin
Access-Control-Allow-Methods: GET, POST, OPTIONS
```

---

## Priority

**Low** - Virtuoso is a niche database/application server with limited audience. Documentation is mostly adequate.

---

## Implementation Checklist

- [ ] Add enhanced VSP example with multiple origins
- [ ] Include preflight OPTIONS handling
- [ ] Show pattern matching for subdomains
- [ ] Add SPARQL endpoint-specific example
- [ ] Document credentials configuration
- [ ] Add performance considerations
- [ ] Show reusable CORS procedure
- [ ] Include comprehensive testing examples
- [ ] Add security warnings about wildcards
- [ ] Document version requirements clearly
- [ ] Link to updated Virtuoso documentation

---

## Related Resources

- [Virtuoso CORS Setup Guide](http://virtuoso.openlinksw.com/dataspace/dav/wiki/Main/VirtTipsAndTricksGuideCORSSetup)
- [Virtuoso Open Source Documentation](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/)
- [Virtuoso HTTP Functions](http://docs.openlinksw.com/virtuoso/fn_http_header.html)
- [SPARQL 1.1 Protocol](https://www.w3.org/TR/sparql11-protocol/)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #146: Multi-origin support](https://github.com/monsur/enable-cors.org/issues/146)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** Ready for implementation
