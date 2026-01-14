# CORS Implementation Analysis: CGI

**File Reference:** `/server_cgi.html`
**Technology:** CGI Scripts (Perl/Python)
**Analysis Date:** January 2025
**Status:** ✅ COMPLETED

---

## Current Implementation

Basic header output in CGI scripts:

**Perl (CGI.pm):**
```perl
print header(
  -type => 'text/turtle',
  -content_location => 'mydata.ttl',
  -access_control_allow_origin => '*',
);
```

**Python (Python 2 syntax):**
```python
print "Content-Type: text/turtle"
print "Content-Location: mydata.ttl"
print "Access-Control-Allow-Origin: *"
```

---

## Issues Identified

### Critical
- **C1**: Very outdated approach - CGI is largely deprecated
- **C2**: Shows Python 2 syntax (EOL January 2020)
- **C3**: Wildcard only, no validation ([#152](https://github.com/monsur/enable-cors.org/issues/152))
- **C4**: No preflight OPTIONS handling

### High
- **H1**: Missing deprecation warning
- **H2**: No modern alternatives suggested
- **H3**: Missing Vary header

---

## General Security Best Practices

### 1. Origin Validation
CGI must validate origins:

**Perl:**
```perl
my @allowed_origins = ('https://example.com', 'https://app.example.com');
my $origin = $ENV{HTTP_ORIGIN} || '';

if (grep { $_ eq $origin } @allowed_origins) {
    print "Access-Control-Allow-Origin: $origin\n";
    print "Vary: Origin\n";
}
```

**Python 3:**
```python
import os

allowed_origins = ['https://example.com', 'https://app.example.com']
origin = os.environ.get('HTTP_ORIGIN', '')

if origin in allowed_origins:
    print(f"Access-Control-Allow-Origin: {origin}")
    print("Vary: Origin")
```

### 2. Preflight Handling
```python
import os

if os.environ.get('REQUEST_METHOD') == 'OPTIONS':
    print("Access-Control-Allow-Methods: GET, POST, PUT, DELETE")
    print("Access-Control-Allow-Headers: Content-Type, Authorization")
    print("Access-Control-Max-Age: 86400")
    print("Status: 204 No Content")
    print()
    sys.exit(0)
```

---

## Recommended Improvements

### Add Deprecation Warning

```html
⚠️ DEPRECATION NOTICE: CGI scripts are largely deprecated technology. For new
projects, consider using modern frameworks:
- Python: Flask, Django, FastAPI
- Perl: Plack/PSGI, Dancer2, Mojolicious

This documentation is maintained for legacy systems only.
```

### Python 3 Complete Example

```python
#!/usr/bin/env python3
import os
import sys
import json

# Configuration
ALLOWED_ORIGINS = [
    'https://example.com',
    'https://app.example.com'
]

def enable_cors():
    """Enable CORS with origin validation"""
    origin = os.environ.get('HTTP_ORIGIN', '')

    # Validate origin
    if origin in ALLOWED_ORIGINS:
        print(f"Access-Control-Allow-Origin: {origin}")
        print("Access-Control-Allow-Credentials: true")
        print("Vary: Origin")

    # Handle preflight
    if os.environ.get('REQUEST_METHOD') == 'OPTIONS':
        print("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS")
        print("Access-Control-Allow-Headers: Content-Type, Authorization")
        print("Access-Control-Max-Age: 86400")
        print("Status: 204 No Content")
        print()  # Empty line ends headers
        sys.exit(0)

# Enable CORS
enable_cors()

# Your CGI logic
print("Content-Type: application/json")
print()  # Empty line ends headers

# Response body
response = {
    'status': 'success',
    'message': 'CORS enabled with origin validation'
}
print(json.dumps(response))
```

### Perl Modern Example

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use CGI;
use JSON;

# Configuration
my @ALLOWED_ORIGINS = ('https://example.com', 'https://app.example.com');

sub enable_cors {
    my $origin = $ENV{HTTP_ORIGIN} || '';

    # Validate origin
    if (grep { $_ eq $origin } @ALLOWED_ORIGINS) {
        print "Access-Control-Allow-Origin: $origin\n";
        print "Access-Control-Allow-Credentials: true\n";
        print "Vary: Origin\n";
    }

    # Handle preflight
    if ($ENV{REQUEST_METHOD} eq 'OPTIONS') {
        print "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\n";
        print "Access-Control-Allow-Headers: Content-Type, Authorization\n";
        print "Access-Control-Max-Age: 86400\n";
        print "Status: 204 No Content\n\n";
        exit 0;
    }
}

# Enable CORS
enable_cors();

# Your CGI logic
print "Content-Type: application/json\n\n";

my $response = {
    status => 'success',
    message => 'CORS enabled with origin validation'
};

print encode_json($response);
```

---

## Technology-Specific Considerations

### Why CGI is Deprecated
- **Performance**: New process for each request
- **Resource intensive**: High memory usage
- **Security**: Difficult to secure properly
- **Modern alternatives**: WSGI (Python), PSGI (Perl), FastCGI

### Migration Paths

**Python:**
```bash
# From CGI to Flask
pip install flask
# See Flask CORS documentation
```

**Perl:**
```bash
# From CGI to Plack/PSGI
cpanm Plack
# See Perl PSGI documentation
```

### When CGI is Still Used
- Legacy systems that can't be migrated
- Simple, infrequent operations
- Shared hosting with no framework support
- Embedded systems with limited resources

---

## Testing Instructions

### Test CGI Script
```bash
# Test with curl
curl -H "Origin: https://example.com" \
     -v http://your-server.com/cgi-bin/script.cgi

# Test preflight
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     -v http://your-server.com/cgi-bin/script.cgi
```

### Common CGI Issues
- **Execute permissions**: `chmod +x script.cgi`
- **Shebang line**: Correct path to interpreter
- **Headers before body**: Always print empty line after headers
- **File encoding**: Ensure no BOM in files

---

## Priority

**LOW PRIORITY**

CGI is deprecated technology with declining usage. Documentation should include deprecation notice and migration guidance.

**Impact:** Very Low - Legacy systems only
**Effort:** Low - Add warnings and Python 3 examples

---

## Implementation Checklist

### Immediate
- [x] Add prominent deprecation warning
- [x] Update Python examples to Python 3
- [x] Add migration guidance
- [x] Show modern alternatives

### Short-term
- [x] Add origin validation examples
- [x] Include preflight handling
- [x] Add Vary header
- [x] Link to modern framework pages

### Medium-term
- [x] Create migration guide
- [x] Document when CGI is still appropriate
- [x] Add troubleshooting for common issues

---

## Related Resources

### Modern Alternatives
- **Python**: [Flask](server_flask.html), Django, FastAPI
- **Perl**: [Plack/PSGI](server_perl.html), Dancer2, Mojolicious

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)

### Related enable-cors.org Pages
- [Perl PSGI](server_perl.html) - Modern Perl approach
- [Flask](server_flask.html) - Modern Python framework
- [Apache](server_apache.html) - Often runs CGI scripts

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
