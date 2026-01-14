# CORS Implementation Analysis: Express.js

**File Reference:** `/server_expressjs.html`
**Technology:** Express.js (Node.js Web Framework)
**Analysis Date:** January 2025
**Status:** High Priority - Missing Best Practices

---

## Current Implementation

The current Express.js documentation provides a middleware approach:

### Current Code Example

```javascript
app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "YOUR-DOMAIN.TLD"); // update to match the domain you will make the request from
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});

app.get('/', function(req, res, next) {
  // Handle the get for this route
});

app.post('/', function(req, res, next) {
 // Handle the post for this route
});
```

**Strengths:**
- Shows middleware pattern (Express best practice)
- Demonstrates where to place CORS configuration
- Shows usage with routes

---

## Issues Identified

### Critical Priority

**C1. Placeholder Domain**
- Uses "YOUR-DOMAIN.TLD" which users must remember to replace
- Easy to forget and deploy with placeholder
- **Impact:** Users may deploy broken or overly permissive configurations
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152)

**C2. No Preflight OPTIONS Handling**
- Doesn't show how to handle OPTIONS requests
- Required for non-simple CORS requests
- **Impact:** POST/PUT/DELETE requests with custom headers will fail

**C3. No Origin Validation Logic**
- Shows static origin but no validation
- Doesn't demonstrate how to check multiple origins
- **Impact:** Users don't learn proper origin validation

### High Priority

**H1. Missing `cors` Package Reference**
- Doesn't mention the popular `cors` npm package
- Manual implementation is error-prone
- Package handles all edge cases
- **Impact:** Users reinvent the wheel poorly
- **Related Issue:** [#138](https://github.com/monsur/enable-cors.org/issues/138) - Suggests using cors package

**H2. Missing Vary Header**
- No `Vary: Origin` header shown
- **Impact:** Caching issues when responses vary by origin
- **Related Issue:** [#164](https://github.com/monsur/enable-cors.org/issues/164)

**H3. Incomplete Headers**
- Only shows Allow-Origin and Allow-Headers
- Missing Allow-Methods
- Missing Max-Age for preflight caching
- **Impact:** Incomplete CORS implementation

### Medium Priority

**M1. No Credentials Configuration**
- Doesn't show `Access-Control-Allow-Credentials`
- No example for authenticated APIs
- **Impact:** Cookie-based auth won't work

**M2. No Error Handling**
- Doesn't show what to do when origin is not allowed
- No guidance on rejecting requests
- **Impact:** Unclear security behavior

**M3. Old Express Patterns**
- Could show modern async/await patterns
- Could show route-specific CORS
- **Impact:** Doesn't reflect modern Express development

### Low Priority

**L1. No TypeScript Example**
- Many Express users use TypeScript
- Missing type definitions
- **Impact:** TypeScript users need to figure out types

**L2. No Testing Guidance**
- Doesn't show how to test CORS middleware
- No debugging tips
- **Impact:** Harder to verify correct implementation

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). Validate the origin against a whitelist.

**Secure Approach:**
```javascript
const allowedOrigins = ['https://example.com', 'https://app.example.com'];

app.use(function(req, res, next) {
  const origin = req.headers.origin;

  if (allowedOrigins.includes(origin)) {
    res.header("Access-Control-Allow-Origin", origin);
    res.header("Vary", "Origin");
  }

  next();
});
```

### 2. Preflight Request Handling
OPTIONS requests must be handled:

```javascript
app.use(function(req, res, next) {
  // ... set headers ...

  if (req.method === 'OPTIONS') {
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.header("Access-Control-Max-Age", "86400");
    return res.sendStatus(204);
  }

  next();
});
```

### 3. Credentials and Authentication
When using credentials:

```javascript
res.header("Access-Control-Allow-Origin", origin); // No wildcards!
res.header("Access-Control-Allow-Credentials", "true");
```

### 4. Caching Considerations
Always include `Vary` header:

```javascript
res.header("Vary", "Origin");
```

---

## Recommended Improvements

### Method 1: Using the `cors` Package (Recommended)

```javascript
// Install: npm install cors
const express = require('express');
const cors = require('cors');
const app = express();

// Simple usage - allow specific origin
app.use(cors({
  origin: 'https://example.com',
  credentials: true
}));

// Advanced usage - validate multiple origins
const allowedOrigins = ['https://example.com', 'https://app.example.com'];

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, curl, etc)
    if (!origin) return callback(null, true);

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  optionsSuccessStatus: 204
}));

// Route-specific CORS
app.get('/api/public', cors(), function(req, res) {
  res.json({message: 'Public endpoint'});
});

const corsOptions = {
  origin: 'https://example.com',
  credentials: true
};

app.get('/api/private', cors(corsOptions), function(req, res) {
  res.json({message: 'Private endpoint'});
});

app.listen(3000);
```

### Method 2: Manual Implementation (Without Package)

```javascript
const express = require('express');
const app = express();

// List of allowed origins
const allowedOrigins = [
  'https://example.com',
  'https://app.example.com',
  'https://admin.example.com'
];

// CORS middleware
app.use(function(req, res, next) {
  const origin = req.headers.origin;

  // Validate origin
  if (allowedOrigins.includes(origin)) {
    res.header("Access-Control-Allow-Origin", origin);
    res.header("Vary", "Origin");
    res.header("Access-Control-Allow-Credentials", "true");
  }

  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
  res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.header("Access-Control-Max-Age", "86400");
    return res.sendStatus(204);
  }

  next();
});

// Your routes
app.get('/api/data', function(req, res) {
  res.json({message: 'CORS enabled'});
});

app.post('/api/data', function(req, res) {
  res.json({message: 'CORS enabled for POST'});
});

app.listen(3000, function() {
  console.log('Server running on port 3000');
});
```

### Method 3: Reusable CORS Middleware

```javascript
// cors-middleware.js
function corsMiddleware(options = {}) {
  const {
    origins = [],
    credentials = true,
    methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    headers = ['Content-Type', 'Authorization', 'X-Requested-With'],
    maxAge = 86400
  } = options;

  return function(req, res, next) {
    const origin = req.headers.origin;

    // Validate origin
    if (origins.includes(origin)) {
      res.header("Access-Control-Allow-Origin", origin);
      res.header("Vary", "Origin");

      if (credentials) {
        res.header("Access-Control-Allow-Credentials", "true");
      }
    } else if (origins.length === 0) {
      // Allow all if no origins specified (development only)
      res.header("Access-Control-Allow-Origin", "*");
    }

    res.header("Access-Control-Allow-Methods", methods.join(", "));
    res.header("Access-Control-Allow-Headers", headers.join(", "));

    // Handle preflight
    if (req.method === 'OPTIONS') {
      res.header("Access-Control-Max-Age", maxAge.toString());
      return res.sendStatus(204);
    }

    next();
  };
}

module.exports = corsMiddleware;

// Usage in app.js
const express = require('express');
const corsMiddleware = require('./cors-middleware');
const app = express();

app.use(corsMiddleware({
  origins: ['https://example.com', 'https://app.example.com'],
  credentials: true
}));

app.get('/api/data', (req, res) => {
  res.json({message: 'CORS enabled'});
});

app.listen(3000);
```

### Method 4: TypeScript Implementation

```typescript
// types/express.d.ts
import { Request, Response, NextFunction } from 'express';

export interface CorsOptions {
  origins: string[];
  credentials?: boolean;
  methods?: string[];
  headers?: string[];
  maxAge?: number;
}

// cors-middleware.ts
import { Request, Response, NextFunction } from 'express';
import { CorsOptions } from './types/express';

export function corsMiddleware(options: CorsOptions) {
  const {
    origins,
    credentials = true,
    methods = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    headers = ['Content-Type', 'Authorization', 'X-Requested-With'],
    maxAge = 86400
  } = options;

  return (req: Request, res: Response, next: NextFunction): void => {
    const origin = req.headers.origin;

    if (origin && origins.includes(origin)) {
      res.header("Access-Control-Allow-Origin", origin);
      res.header("Vary", "Origin");

      if (credentials) {
        res.header("Access-Control-Allow-Credentials", "true");
      }
    }

    res.header("Access-Control-Allow-Methods", methods.join(", "));
    res.header("Access-Control-Allow-Headers", headers.join(", "));

    if (req.method === 'OPTIONS') {
      res.header("Access-Control-Max-Age", maxAge.toString());
      res.sendStatus(204);
      return;
    }

    next();
  };
}

// app.ts
import express from 'express';
import { corsMiddleware } from './cors-middleware';

const app = express();

app.use(corsMiddleware({
  origins: ['https://example.com', 'https://app.example.com'],
  credentials: true
}));

app.get('/api/data', (req, res) => {
  res.json({message: 'CORS enabled'});
});

app.listen(3000);
```

### Method 5: Async Origin Validation

```javascript
const express = require('express');
const cors = require('cors');
const app = express();

// Async origin validation (e.g., check database)
const corsOptions = {
  origin: async function (origin, callback) {
    try {
      // Example: Check if origin is in database
      const isAllowed = await checkOriginInDatabase(origin);

      if (isAllowed) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    } catch (error) {
      callback(error);
    }
  },
  credentials: true
};

async function checkOriginInDatabase(origin) {
  // Simulate database check
  const allowedOrigins = await db.getAllowedOrigins();
  return allowedOrigins.includes(origin);
}

app.use(cors(corsOptions));

app.get('/api/data', (req, res) => {
  res.json({message: 'Dynamic origin validation'});
});

app.listen(3000);
```

### Security Warning to Add

```html
⚠️ Security Warning: Never deploy with placeholder domains like "YOUR-DOMAIN.TLD".
Always replace with your actual allowed origins. For production applications, use
the 'cors' npm package or implement proper origin validation as shown in the examples.
```

### Package Installation Note

```markdown
## Recommended: Using the `cors` Package

The `cors` npm package is the standard solution for Express.js CORS handling.
It's well-maintained, handles all edge cases, and is used by millions of projects.

### Installation
npm install cors

### Why use the package?
- Handles preflight requests automatically
- Validates origins correctly
- Supports async origin validation
- Well-tested and maintained
- Handles edge cases you might miss

### Package Documentation
https://www.npmjs.com/package/cors
```

---

## Technology-Specific Considerations

### Express Middleware Order

Middleware order matters:

```javascript
const express = require('express');
const cors = require('cors');
const app = express();

// 1. CORS must come before routes
app.use(cors({origin: 'https://example.com'}));

// 2. Then body parsers
app.use(express.json());

// 3. Then your routes
app.get('/api/data', (req, res) => {
  res.json({data: 'value'});
});
```

### Route-Specific CORS

Different endpoints may need different CORS policies:

```javascript
// Public API - open CORS
app.get('/api/public', cors(), (req, res) => {
  res.json({public: true});
});

// Private API - restricted CORS
const privateCors = cors({
  origin: 'https://example.com',
  credentials: true
});

app.get('/api/private', privateCors, (req, res) => {
  res.json({private: true});
});

// No CORS
app.get('/internal', (req, res) => {
  res.json({internal: true});
});
```

### Express Behind Proxy

When Express is behind a reverse proxy (Nginx, Apache):

```javascript
// Trust proxy (required for correct origin detection)
app.set('trust proxy', true);

// CORS configuration
app.use(cors({
  origin: function(origin, callback) {
    // origin will now be correct even behind proxy
    callback(null, true);
  }
}));
```

### Error Handling

Handle CORS errors gracefully:

```javascript
const corsOptions = {
  origin: function(origin, callback) {
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  }
};

app.use(cors(corsOptions));

// Error handler for CORS errors
app.use(function(err, req, res, next) {
  if (err.message === 'Not allowed by CORS') {
    res.status(403).json({
      error: 'CORS error',
      message: 'Origin not allowed'
    });
  } else {
    next(err);
  }
});
```

### Performance Considerations

Cache origin validation:

```javascript
// Simple in-memory cache
const originCache = new Map();

const corsOptions = {
  origin: function(origin, callback) {
    if (originCache.has(origin)) {
      callback(null, originCache.get(origin));
      return;
    }

    const isAllowed = allowedOrigins.includes(origin);
    originCache.set(origin, isAllowed);
    callback(null, isAllowed);
  }
};
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
     -v http://localhost:3000/api/endpoint

# Test actual request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"test":"data"}' \
     -v http://localhost:3000/api/endpoint
```

### 2. Test with Browser

```javascript
fetch('http://localhost:3000/api/data', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  credentials: 'include',
  body: JSON.stringify({test: 'data'})
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

### 3. Automated Testing

```javascript
// test/cors.test.js
const request = require('supertest');
const app = require('../app');

describe('CORS', () => {
  it('should allow allowed origin', async () => {
    const response = await request(app)
      .get('/api/data')
      .set('Origin', 'https://example.com')
      .expect(200);

    expect(response.headers['access-control-allow-origin'])
      .toBe('https://example.com');
  });

  it('should reject disallowed origin', async () => {
    const response = await request(app)
      .get('/api/data')
      .set('Origin', 'https://evil.com');

    expect(response.headers['access-control-allow-origin'])
      .toBeUndefined();
  });

  it('should handle preflight', async () => {
    const response = await request(app)
      .options('/api/data')
      .set('Origin', 'https://example.com')
      .set('Access-Control-Request-Method', 'POST')
      .expect(204);

    expect(response.headers['access-control-allow-methods'])
      .toContain('POST');
  });
});
```

### 4. Debug CORS Issues

```javascript
// Enable debug logging
const cors = require('cors');

app.use((req, res, next) => {
  console.log('Origin:', req.headers.origin);
  console.log('Method:', req.method);
  next();
});

app.use(cors({
  origin: function(origin, callback) {
    console.log('Checking origin:', origin);
    callback(null, true);
  }
}));
```

---

## Priority

**HIGH PRIORITY**

**Justification:**
- Express.js is one of the most popular Node.js frameworks
- Current example uses placeholder that may be deployed
- Missing the recommended `cors` package ([#138](https://github.com/monsur/enable-cors.org/issues/138))
- No preflight handling shown
- High impact on Node.js ecosystem

**Impact:** High - Express.js is extremely popular

**Effort:** Low - Examples are straightforward to add

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Replace placeholder with real example origin
- [ ] Add `cors` package as primary recommendation
- [ ] Show preflight OPTIONS handling
- [ ] Add origin validation example
- [ ] Include security warning
- [ ] Reference [#138](https://github.com/monsur/enable-cors.org/issues/138)

### Short-term Actions (High Priority)
- [ ] Add `Vary: Origin` header to examples
- [ ] Show credentials configuration
- [ ] Add route-specific CORS examples
- [ ] Include TypeScript example
- [ ] Document manual implementation as alternative

### Medium-term Actions
- [ ] Add testing examples
- [ ] Show async origin validation
- [ ] Document proxy considerations
- [ ] Add error handling patterns
- [ ] Include performance tips

### Long-term Actions
- [ ] Create Express CORS troubleshooting guide
- [ ] Add video tutorial
- [ ] Create interactive example generator
- [ ] Document integration with authentication middleware

---

## Related Resources

### Official Documentation
- [cors npm package](https://www.npmjs.com/package/cors)
- [Express.js Official Docs](https://expressjs.com/)
- [Express Middleware Guide](https://expressjs.com/en/guide/using-middleware.html)

### Related GitHub Issues
- [#138 - CORS on Express - Use cors package](https://github.com/monsur/enable-cors.org/issues/138)
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Additional Resources
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Express Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)

### Related enable-cors.org Pages
- [Node.js CORS](server_meteor.html) - Another Node.js framework
- [Flask CORS](server_flask.html) - Similar web framework pattern

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** ✅ Implementation Complete
