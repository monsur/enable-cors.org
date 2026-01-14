# CORS Implementation Analysis: Flask

**File Reference:** `/server_flask.html`
**Technology:** Flask (Python Web Framework)
**Analysis Date:** January 2025
**Status:** Medium Priority - Good Foundation, Needs Enhancement

---

## Current Implementation

The current Flask documentation uses the Flask-CORS package:

### Current Code Example

```python
# app.py
from flask import Flask
from flask_cors import CORS
app = Flask(__name__)
cors = CORS(app)
```

**Installation:**
```bash
$ pip install -U flask-cors
```

**Strengths:**
- Uses well-maintained package (best practice)
- Clean, simple example
- Links to full documentation
- Shows proper installation

---

## Issues Identified

### Critical Priority

**C1. No Configuration Shown**
- Example uses default settings (wildcard CORS)
- Doesn't show how to configure origins
- No security warnings about defaults
- **Impact:** Users will deploy with insecure wildcard configuration
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152)

### High Priority

**H1. Missing Origin Validation Example**
- Doesn't demonstrate how to restrict origins
- No example of origin whitelist
- **Impact:** Users don't know how to secure their CORS setup
- **Related Issue:** [#146](https://github.com/monsur/enable-cors.org/issues/146)

**H2. No Configuration Options Explained**
- Flask-CORS has many options
- Doesn't show methods, headers, credentials configuration
- **Impact:** Users miss important features

**H3. Missing Route-Specific CORS**
- Doesn't show `@cross_origin` decorator
- No example of path-specific CORS
- **Impact:** Over-permissive CORS on all routes

### Medium Priority

**M1. No Security Warning**
- Doesn't explain Flask-CORS defaults to wildcard
- No warning about public vs private APIs
- **Impact:** Unintentional security vulnerabilities

**M2. Missing Credentials Configuration**
- Doesn't show `supports_credentials` option
- No authenticated API example
- **Impact:** Cookie-based auth won't work

**M3. No Troubleshooting Guidance**
- Doesn't explain common Flask-CORS issues
- Missing debugging tips
- **Impact:** Users struggle with issues

### Low Priority

**L1. Limited Context**
- Doesn't explain when to use Flask-CORS
- Missing use cases
- **Impact:** Users may not understand when it's appropriate

**L2. No Alternative Approaches**
- Could show manual implementation
- Could mention blueprints integration
- **Impact:** Users only know one approach

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). Flask-CORS handles this by accepting a list of origins.

**Secure Approach:**
```python
from flask_cors import CORS

CORS(app, origins=[
    "https://example.com",
    "https://app.example.com"
])
```

### 2. Preflight Request Handling
Flask-CORS automatically handles OPTIONS preflight requests. No manual configuration needed.

### 3. Credentials and Authentication
When using credentials:

```python
CORS(app, origins=["https://example.com"], supports_credentials=True)
```

### 4. Caching Considerations
Flask-CORS automatically adds `Vary: Origin` when needed.

---

## Recommended Improvements

### Method 1: Secure Global Configuration

```python
# app.py
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Secure configuration - specify allowed origins
CORS(app, origins=[
    "https://example.com",
    "https://app.example.com"
])

@app.route('/api/data')
def get_data():
    return {'message': 'CORS enabled with origin validation'}

if __name__ == '__main__':
    app.run()
```

### Method 2: Detailed Configuration

```python
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Detailed CORS configuration
cors = CORS(app, resources={
    r"/api/*": {
        "origins": ["https://example.com", "https://app.example.com"],
        "methods": ["GET", "POST", "PUT", "DELETE"],
        "allow_headers": ["Content-Type", "Authorization"],
        "expose_headers": ["Content-Length", "X-Custom-Header"],
        "supports_credentials": True,
        "max_age": 86400
    }
})

@app.route('/api/data')
def get_data():
    return {'data': 'value'}

@app.route('/api/users', methods=['POST'])
def create_user():
    return {'status': 'created'}, 201

if __name__ == '__main__':
    app.run()
```

### Method 3: Route-Specific CORS with Decorator

```python
from flask import Flask
from flask_cors import CORS, cross_origin

app = Flask(__name__)

# No global CORS

# Public endpoint - open CORS
@app.route('/api/public')
@cross_origin()
def public_endpoint():
    return {'public': True}

# Private endpoint - restricted CORS
@app.route('/api/private')
@cross_origin(origins=["https://example.com"], supports_credentials=True)
def private_endpoint():
    return {'private': True}

# No CORS on this route
@app.route('/internal')
def internal_endpoint():
    return {'internal': True}

if __name__ == '__main__':
    app.run()
```

### Method 4: Environment-Based Configuration

```python
import os
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Configuration from environment
if os.getenv('FLASK_ENV') == 'development':
    # Development - allow localhost
    CORS(app, origins=[
        "http://localhost:3000",
        "http://localhost:8080"
    ])
else:
    # Production - strict origins
    CORS(app, origins=[
        "https://example.com",
        "https://app.example.com"
    ], supports_credentials=True)

@app.route('/api/data')
def get_data():
    return {'message': 'CORS configured by environment'}

if __name__ == '__main__':
    app.run()
```

### Method 5: Blueprint Integration

```python
# api/blueprint.py
from flask import Blueprint
from flask_cors import cross_origin

api_bp = Blueprint('api', __name__, url_prefix='/api')

@api_bp.route('/data')
@cross_origin(origins=["https://example.com"])
def get_data():
    return {'data': 'value'}

# app.py
from flask import Flask
from flask_cors import CORS
from api.blueprint import api_bp

app = Flask(__name__)

# Apply CORS to specific blueprint
CORS(api_bp, origins=["https://example.com"])

app.register_blueprint(api_bp)

if __name__ == '__main__':
    app.run()
```

### Method 6: Dynamic Origin Validation

```python
from flask import Flask, request
from flask_cors import CORS

app = Flask(__name__)

def check_origin(origin, *args, **kwargs):
    """
    Custom origin validation function
    Can check database, perform regex matching, etc.
    """
    # Example: Check against database
    allowed_origins = get_allowed_origins_from_db()
    return origin in allowed_origins

# Use custom origin checker
CORS(app, origins=check_origin, supports_credentials=True)

@app.route('/api/data')
def get_data():
    return {'message': 'Dynamic origin validation'}

def get_allowed_origins_from_db():
    # Simulate database lookup
    return ["https://example.com", "https://app.example.com"]

if __name__ == '__main__':
    app.run()
```

### Method 7: Manual Implementation (Without Flask-CORS)

```python
from flask import Flask, request, make_response
from functools import wraps

app = Flask(__name__)

ALLOWED_ORIGINS = [
    'https://example.com',
    'https://app.example.com'
]

def cors_enabled(f):
    """
    Decorator to enable CORS on specific routes
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        origin = request.headers.get('Origin')

        # Handle preflight
        if request.method == 'OPTIONS':
            response = make_response()
            if origin in ALLOWED_ORIGINS:
                response.headers['Access-Control-Allow-Origin'] = origin
                response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
                response.headers['Access-Control-Max-Age'] = '86400'
                response.headers['Vary'] = 'Origin'
            response.status_code = 204
            return response

        # Handle actual request
        response = make_response(f(*args, **kwargs))
        if origin in ALLOWED_ORIGINS:
            response.headers['Access-Control-Allow-Origin'] = origin
            response.headers['Access-Control-Allow-Credentials'] = 'true'
            response.headers['Vary'] = 'Origin'

        return response

    return decorated_function

@app.route('/api/data')
@cors_enabled
def get_data():
    return {'message': 'Manual CORS implementation'}

if __name__ == '__main__':
    app.run()
```

### Configuration Reference Table

```markdown
## Flask-CORS Configuration Options

| Parameter | Description | Example |
|-----------|-------------|---------|
| `origins` | Allowed origins (string, list, or regex) | `["https://example.com"]` |
| `methods` | Allowed HTTP methods | `["GET", "POST", "PUT", "DELETE"]` |
| `allow_headers` | Headers client can send | `["Content-Type", "Authorization"]` |
| `expose_headers` | Headers client can read | `["Content-Length", "X-Custom"]` |
| `supports_credentials` | Allow cookies/auth | `True` or `False` |
| `max_age` | Preflight cache duration (seconds) | `86400` (24 hours) |
| `send_wildcard` | Send * instead of origin | `False` (recommended) |
| `always_send` | Send CORS headers for all responses | `True` (default) |
| `automatic_options` | Handle OPTIONS automatically | `True` (default) |
| `vary_header` | Add Vary: Origin header | `True` (default) |
```

### Security Warning to Add

```html
⚠️ Security Warning: By default, Flask-CORS allows ALL origins (*). Always
specify the `origins` parameter to restrict access to trusted domains. Never
use the default configuration in production for sensitive APIs.
```

---

## Technology-Specific Considerations

### Flask Application Factory Pattern

```python
# app/__init__.py
from flask import Flask
from flask_cors import CORS

def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config_name)

    # Configure CORS
    cors = CORS(app, resources={
        r"/api/*": {
            "origins": app.config.get('CORS_ORIGINS', []),
            "supports_credentials": True
        }
    })

    # Register blueprints
    from .api import api_bp
    app.register_blueprint(api_bp)

    return app

# config.py
class ProductionConfig:
    CORS_ORIGINS = [
        'https://example.com',
        'https://app.example.com'
    ]

class DevelopmentConfig:
    CORS_ORIGINS = [
        'http://localhost:3000',
        'http://localhost:8080'
    ]
```

### Integration with Flask-RESTful

```python
from flask import Flask
from flask_restful import Api, Resource
from flask_cors import CORS

app = Flask(__name__)
api = Api(app)

# Enable CORS for all API routes
CORS(app, resources={r"/api/*": {"origins": "https://example.com"}})

class UserAPI(Resource):
    def get(self, user_id):
        return {'user_id': user_id}

    def post(self):
        return {'status': 'created'}, 201

api.add_resource(UserAPI, '/api/users/<int:user_id>')

if __name__ == '__main__':
    app.run()
```

### Flask-Login Integration

```python
from flask import Flask
from flask_cors import CORS
from flask_login import LoginManager, login_required

app = Flask(__name__)
login_manager = LoginManager(app)

# CORS with credentials for authenticated endpoints
CORS(app, origins=["https://example.com"], supports_credentials=True)

@app.route('/api/protected')
@login_required
def protected():
    return {'message': 'Authenticated CORS request'}

if __name__ == '__main__':
    app.run()
```

### Debugging CORS Issues

```python
from flask import Flask
from flask_cors import CORS
import logging

app = Flask(__name__)

# Enable debug logging
logging.getLogger('flask_cors').level = logging.DEBUG

CORS(app, origins=["https://example.com"])

@app.route('/api/data')
def get_data():
    # Flask-CORS will log CORS decision process
    return {'data': 'value'}

if __name__ == '__main__':
    app.run(debug=True)
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
     -v http://localhost:5000/api/endpoint

# Test actual request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"test":"data"}' \
     -v http://localhost:5000/api/endpoint
```

### 2. Test in Python

```python
import requests

# Test CORS request
response = requests.get(
    'http://localhost:5000/api/data',
    headers={'Origin': 'https://example.com'}
)

print('Status:', response.status_code)
print('CORS Headers:')
print('  Allow-Origin:', response.headers.get('Access-Control-Allow-Origin'))
print('  Allow-Credentials:', response.headers.get('Access-Control-Allow-Credentials'))
print('  Vary:', response.headers.get('Vary'))
```

### 3. Automated Testing with pytest

```python
# test_cors.py
import pytest
from app import app

@pytest.fixture
def client():
    with app.test_client() as client:
        yield client

def test_cors_allowed_origin(client):
    response = client.get(
        '/api/data',
        headers={'Origin': 'https://example.com'}
    )
    assert response.headers['Access-Control-Allow-Origin'] == 'https://example.com'

def test_cors_disallowed_origin(client):
    response = client.get(
        '/api/data',
        headers={'Origin': 'https://evil.com'}
    )
    assert 'Access-Control-Allow-Origin' not in response.headers

def test_cors_preflight(client):
    response = client.options(
        '/api/data',
        headers={
            'Origin': 'https://example.com',
            'Access-Control-Request-Method': 'POST'
        }
    )
    assert response.status_code == 200
    assert 'POST' in response.headers['Access-Control-Allow-Methods']
```

### 4. Browser Testing

```javascript
fetch('http://localhost:5000/api/data', {
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

---

## Priority

**MEDIUM PRIORITY**

**Justification:**
- Uses best practice (Flask-CORS package) ✓
- Clean, simple example ✓
- But lacks configuration examples
- Defaults to insecure wildcard
- Popular Python framework needs better guidance

**Impact:** Medium - Good foundation but needs security enhancements

**Effort:** Low - Mainly adding configuration examples

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Add security warning about Flask-CORS defaults
- [ ] Show origins parameter usage
- [ ] Add secure configuration example
- [ ] Link to [#152](https://github.com/monsur/enable-cors.org/issues/152)

### Short-term Actions (High Priority)
- [ ] Add configuration options reference table
- [ ] Show route-specific CORS with @cross_origin
- [ ] Include credentials configuration
- [ ] Add environment-based configuration example
- [ ] Show blueprint integration

### Medium-term Actions
- [ ] Add testing examples
- [ ] Document dynamic origin validation
- [ ] Show Flask-RESTful integration
- [ ] Add debugging guidance
- [ ] Include manual implementation alternative

### Long-term Actions
- [ ] Create Flask CORS troubleshooting guide
- [ ] Add video tutorial
- [ ] Document performance considerations
- [ ] Create interactive configuration generator

---

## Related Resources

### Official Documentation
- [Flask-CORS Documentation](https://flask-cors.readthedocs.io/)
- [Flask Official Docs](https://flask.palletsprojects.com/)
- [Flask-CORS PyPI](https://pypi.org/project/Flask-CORS/)

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Additional Resources
- [Flask-CORS GitHub](https://github.com/corydolphin/flask-cors)
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Flask Testing Guide](https://flask.palletsprojects.com/en/latest/testing/)

### Related enable-cors.org Pages
- [Express.js CORS](server_expressjs.html) - Similar web framework pattern
- [App Engine Python CORS](server_appengine.html) - Flask on GCP

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
