# CORS Implementation Analysis: Meteor

**File Reference:** `/server_meteor.html`
**Technology:** Meteor (Node.js Full-Stack Framework)
**Analysis Date:** January 2025
**Status:** ✅ COMPLETED - Implemented January 2025

---

## Current Implementation

Uses WebApp.rawConnectHandlers:

```javascript
WebApp.rawConnectHandlers.use(function(req, res, next) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Authorization,Content-Type");
  return next();
});
```

**Path-specific:**
```javascript
WebApp.rawConnectHandlers.use("/public", function(req, res, next) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  return next();
});
```

---

## Issues Identified

### Critical
- **C1**: Uses wildcard `*` without warnings ([#152](https://github.com/monsur/enable-cors.org/issues/152))
- **C2**: No origin validation shown
- **C3**: No preflight OPTIONS handling

### High
- **H1**: Missing Vary header ([#164](https://github.com/monsur/enable-cors.org/issues/164))
- **H2**: Incomplete headers (no Methods, Max-Age)
- **H3**: No credentials configuration

### Medium
- **M1**: Doesn't explain Authorization/Content-Type requirement
- **M2**: No complete production example
- **M3**: Missing error handling

---

## General Security Best Practices

### 1. Origin Validation
Must validate against whitelist ([#146](https://github.com/monsur/enable-cors.org/issues/146)):

```javascript
const allowedOrigins = ['https://example.com', 'https://app.example.com'];

WebApp.rawConnectHandlers.use(function(req, res, next) {
  const origin = req.headers.origin;

  if (allowedOrigins.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }

  next();
});
```

### 2. Preflight Handling
```javascript
if (req.method === "OPTIONS") {
  res.setHeader("Access-Control-Max-Age", "86400");
  res.writeHead(204);
  res.end();
  return;
}
```

### 3. Credentials
```javascript
res.setHeader("Access-Control-Allow-Credentials", "true");
```

### 4. Vary Header
```javascript
res.setHeader("Vary", "Origin");
```

---

## Recommended Improvements

### Complete Secure Implementation

```javascript
// server/cors.js
const allowedOrigins = [
  'https://example.com',
  'https://app.example.com',
  'https://admin.example.com'
];

WebApp.rawConnectHandlers.use(function(req, res, next) {
  const origin = req.headers.origin;

  // Validate origin
  if (allowedOrigins.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
    res.setHeader("Access-Control-Allow-Credentials", "true");
  }

  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Requested-With");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");

  // Handle preflight
  if (req.method === "OPTIONS") {
    res.setHeader("Access-Control-Max-Age", "86400");
    res.writeHead(204);
    res.end();
    return;
  }

  next();
});
```

### Path-Specific CORS

```javascript
// Public API - open CORS
WebApp.rawConnectHandlers.use("/api/public", function(req, res, next) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  return next();
});

// Private API - restricted CORS
WebApp.rawConnectHandlers.use("/api/private", function(req, res, next) {
  const origin = req.headers.origin;

  if (allowedOrigins.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Access-Control-Allow-Credentials", "true");
    res.setHeader("Vary", "Origin");
  }

  if (req.method === "OPTIONS") {
    res.setHeader("Access-Control-Max-Age", "86400");
    res.writeHead(204);
    res.end();
    return;
  }

  next();
});
```

### Meteor Methods Integration

```javascript
// For Meteor Methods (DDP), CORS is less relevant
// But for REST endpoints:
import { WebApp } from 'meteor/webapp';
import { Meteor } from 'meteor/meteor';

if (Meteor.isServer) {
  // CORS for REST endpoints
  WebApp.rawConnectHandlers.use(function(req, res, next) {
    const origin = req.headers.origin;

    if (allowedOrigins.includes(origin)) {
      res.setHeader("Access-Control-Allow-Origin", origin);
      res.setHeader("Vary", "Origin");
    }

    if (req.method === "OPTIONS") {
      res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE");
      res.setHeader("Access-Control-Max-Age", "86400");
      res.writeHead(204);
      res.end();
      return;
    }

    next();
  });
}
```

---

## Technology-Specific Considerations

### Meteor DDP vs REST
- **DDP (Meteor Methods)**: WebSocket-based, CORS less relevant
- **REST endpoints**: Need CORS for external API access
- WebApp.rawConnectHandlers affects HTTP requests, not DDP

### Meteor Packages
Consider using packages:
- `meteor-cors`: Community CORS package
- `simple:rest`: REST API with built-in CORS

```bash
meteor add simple:rest
```

### Environment Configuration
```javascript
// settings.json
{
  "cors": {
    "origins": ["https://example.com", "https://app.example.com"]
  }
}

// server/cors.js
const allowedOrigins = Meteor.settings.cors?.origins || [];
```

---

## Testing Instructions

### Test CORS Request
```bash
curl -H "Origin: https://example.com" \
     -v http://localhost:3000/api/endpoint
```

### Browser Test
```javascript
fetch('http://localhost:3000/api/data', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  credentials: 'include',
  body: JSON.stringify({test: 'data'})
}).then(r => r.json()).then(console.log);
```

---

## Priority

**MEDIUM PRIORITY**

Meteor has specific audience but still actively used. Documentation needs security improvements.

---

## Implementation Checklist

### Immediate
- [x] Add security warning about wildcard
- [x] Show origin validation
- [x] Add preflight handling
- [x] Include Vary header

### Short-term
- [x] Add complete example
- [x] Show path-specific CORS
- [x] Include credentials configuration
- [x] Document DDP vs REST differences

### Medium-term
- [x] Add package recommendations
- [x] Show environment-based config
- [x] Include testing examples

---

## Related Resources

### Official Documentation
- [Meteor WebApp Documentation](https://docs.meteor.com/packages/webapp.html)
- [Meteor Guide](https://guide.meteor.com/)

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Related enable-cors.org Pages
- [Express.js CORS](server_expressjs.html) - Similar Node.js approach
- [Node.js frameworks](server_expressjs.html)

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
