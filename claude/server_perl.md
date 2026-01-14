# CORS Implementation Analysis: Perl

**File Reference:** `/server_perl.html`
**Technology:** Perl (PSGI/Plack)
**Analysis Date:** January 2025
**Status:** ✅ COMPLETED - Implemented January 2025

---

## Current Implementation

The current Perl documentation uses Plack middleware:

### Current Code Example

```perl
enable 'CrossOrigin', origins => '*';
```

**Strengths:**
- Uses middleware package (best practice)
- Very concise
- Mentions Debian/Ubuntu package availability (`libplack-middleware-crossorigin-perl`)
- References CGI page for other Perl uses

---

## Issues Identified

### Critical Priority

**C1. Wildcard Only**
- Only shows wildcard `*` origin
- No secure alternative provided
- No security warning
- **Impact:** All Perl implementations will be insecure
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152)

### High Priority

**H1. No Configuration Examples**
- Doesn't show how to validate specific origins
- Missing methods, headers configuration
- No example of full configuration
- **Impact:** Users don't know middleware capabilities
- **Related Issue:** [#146](https://github.com/monsur/enable-cors.org/issues/146)

**H2. Minimal Documentation**
- Only three lines of example code
- No explanation of how it works
- Missing context
- **Impact:** Users need to search external documentation

### Medium Priority

**M1. No Regex Validation Example**
- Plack::Middleware::CrossOrigin supports regex
- Not shown in examples
- **Impact:** Miss useful feature for subdomain matching

**M2. No Credentials Configuration**
- Doesn't show credentials support
- Missing authenticated API example
- **Impact:** Cookie-based auth won't work

**M3. Missing Link**
- Should link to full middleware documentation
- Only mentions the package name
- **Impact:** Users must search for documentation

### Low Priority

**L1. Limited Audience**
- Perl/PSGI is niche compared to other technologies
- Still used in legacy systems
- **Impact:** Lower priority but still needs attention

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). Plack::Middleware::CrossOrigin validates origins from a list or regex.

**Secure Approach:**
```perl
enable 'CrossOrigin',
    origins => 'https://example.com https://app.example.com';
```

### 2. Preflight Request Handling
Plack::Middleware::CrossOrigin automatically handles OPTIONS preflight requests.

### 3. Credentials and Authentication
When using credentials:

```perl
enable 'CrossOrigin',
    origins => 'https://example.com',
    credentials => 1;
```

### 4. Caching Considerations
The middleware automatically handles the `Vary` header.

---

## Recommended Improvements

### Method 1: Secure Origin List

```perl
#!/usr/bin/env perl
use Plack::Builder;

my $app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'application/json' ],
             [ '{"message":"CORS enabled"}' ] ];
};

builder {
    # Recommended: Specific origins
    enable 'CrossOrigin',
        origins => 'https://example.com https://app.example.com',
        methods => ['GET', 'POST', 'PUT', 'DELETE'],
        headers => ['Content-Type', 'Authorization'],
        max_age => 86400;

    $app;
};
```

### Method 2: Regex-Based Origin Matching

```perl
use Plack::Builder;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ];
};

builder {
    # Match origins using regex
    enable 'CrossOrigin',
        origins => qr{^https?://(.+\.)?example\.com$},
        credentials => 1,
        methods => ['GET', 'POST', 'PUT', 'DELETE'],
        headers => ['Content-Type', 'Authorization'];

    $app;
};
```

### Method 3: Path-Specific CORS

```perl
use Plack::Builder;

my $app = sub {
    my $env = shift;
    my $path = $env->{PATH_INFO};

    if ($path eq '/api/data') {
        return [ 200, [ 'Content-Type' => 'application/json' ],
                 [ '{"data":"value"}' ] ];
    }

    return [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not Found' ] ];
};

builder {
    # Public API - open CORS
    mount '/public' => builder {
        enable 'CrossOrigin', origins => '*';
        $app;
    };

    # Private API - restricted CORS
    mount '/api' => builder {
        enable 'CrossOrigin',
            origins => 'https://example.com',
            credentials => 1;
        $app;
    };
};
```

### Method 4: Full Configuration

```perl
use Plack::Builder;

my $app = sub {
    my $env = shift;
    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ '{"status":"success"}' ]
    ];
};

builder {
    enable 'CrossOrigin',
        # Allowed origins (space-separated string or regex)
        origins => 'https://example.com https://app.example.com',

        # Allowed HTTP methods
        methods => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],

        # Allowed request headers
        headers => ['Content-Type', 'Authorization', 'X-Requested-With'],

        # Exposed response headers
        expose_headers => ['Content-Length', 'X-Custom-Header'],

        # Allow credentials (cookies, HTTP auth)
        credentials => 1,

        # Preflight cache duration (seconds)
        max_age => 86400; # 24 hours

    $app;
};
```

### Method 5: Environment-Based Configuration

```perl
use Plack::Builder;

my $app = sub { [ 200, [], [ 'OK' ] ] };

# Get environment
my $env_name = $ENV{PLACK_ENV} || 'development';

builder {
    if ($env_name eq 'development') {
        # Development - allow localhost
        enable 'CrossOrigin',
            origins => 'http://localhost:3000 http://localhost:8080';
    } else {
        # Production - strict origins
        enable 'CrossOrigin',
            origins => 'https://example.com https://app.example.com',
            credentials => 1,
            max_age => 86400;
    }

    $app;
};
```

### Method 6: Dynamic Origin Validation

```perl
use Plack::Builder;

my $app = sub { [ 200, [], [ 'OK' ] ] };

# Load allowed origins from configuration
my @allowed_origins = load_allowed_origins();

builder {
    # Create regex from allowed origins
    my $pattern = join('|', map { quotemeta($_) } @allowed_origins);
    my $origins_regex = qr{^($pattern)$};

    enable 'CrossOrigin',
        origins => $origins_regex,
        credentials => 1;

    $app;
};

sub load_allowed_origins {
    # Could load from file, database, etc.
    return (
        'https://example.com',
        'https://app.example.com',
        'https://admin.example.com'
    );
}
```

### Method 7: Manual Implementation (Without Middleware)

```perl
use Plack::Builder;
use Plack::Request;

my @ALLOWED_ORIGINS = (
    'https://example.com',
    'https://app.example.com'
);

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $origin = $req->header('Origin') || '';

    # Check if origin is allowed
    my $origin_allowed = grep { $_ eq $origin } @ALLOWED_ORIGINS;

    # Handle preflight OPTIONS request
    if ($req->method eq 'OPTIONS') {
        my @headers = (
            'Content-Type' => 'text/plain',
        );

        if ($origin_allowed) {
            push @headers,
                'Access-Control-Allow-Origin' => $origin,
                'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
                'Access-Control-Max-Age' => '86400',
                'Vary' => 'Origin';
        }

        return [ 204, \@headers, [] ];
    }

    # Handle actual request
    my @response_headers = ( 'Content-Type' => 'application/json' );

    if ($origin_allowed) {
        push @response_headers,
            'Access-Control-Allow-Origin' => $origin,
            'Access-Control-Allow-Credentials' => 'true',
            'Vary' => 'Origin';
    }

    return [
        200,
        \@response_headers,
        [ '{"message":"Manual CORS implementation"}' ]
    ];
};
```

### Configuration Reference

```markdown
## Plack::Middleware::CrossOrigin Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `origins` | String, Regex | Allowed origins (space-separated) | `'https://example.com'` |
| `methods` | ArrayRef | Allowed HTTP methods | `['GET', 'POST', 'PUT']` |
| `headers` | ArrayRef | Allowed request headers | `['Content-Type', 'Authorization']` |
| `expose_headers` | ArrayRef | Headers to expose to client | `['Content-Length']` |
| `credentials` | Boolean | Allow credentials | `1` or `0` |
| `max_age` | Integer | Preflight cache duration (seconds) | `86400` |

### Origin Matching Examples

# Exact match (space-separated)
origins => 'https://example.com https://app.example.com'

# Regex match
origins => qr{^https://.*\.example\.com$}

# Wildcard (not recommended)
origins => '*'
```

### Security Warning to Add

```html
⚠️ Security Warning: Using origins => '*' allows ANY website to access your
resources. Only use this for completely public APIs. For production applications,
specify allowed origins explicitly using a space-separated string or regex pattern.
```

---

## Technology-Specific Considerations

### PSGI/Plack Architecture

Plack middleware wraps your application:

```perl
# Middleware execution order (outside-in)
builder {
    enable 'AccessLog';        # 1. Logging (first)
    enable 'CrossOrigin', ...;  # 2. CORS
    enable 'Session';          # 3. Session
    $app;                      # 4. Your app (last)
};
```

### Starman/Plackup Deployment

```bash
# Development
plackup app.psgi

# Production with Starman
starman --workers 10 --port 5000 app.psgi

# With environment
PLACK_ENV=production starman app.psgi
```

### Integration with Web Frameworks

**Dancer2:**
```perl
use Dancer2;
use Plack::Builder;

# Your Dancer2 app
get '/api/data' => sub {
    return { message => 'CORS enabled' };
};

# Wrap with CORS
builder {
    enable 'CrossOrigin',
        origins => 'https://example.com',
        credentials => 1;

    dance;
};
```

**Mojolicious:**
```perl
# Mojolicious has built-in CORS support
$app->hook(after_build_tx => sub {
    my $tx = shift;
    $tx->res->headers->header('Access-Control-Allow-Origin' => 'https://example.com');
});
```

### Performance Considerations

```perl
# Cache origin validation
my %origin_cache;

builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            my $origin = $env->{HTTP_ORIGIN};

            # Check cache
            if (exists $origin_cache{$origin}) {
                # Use cached result
            } else {
                # Validate and cache
                $origin_cache{$origin} = validate_origin($origin);
            }

            $app->($env);
        };
    };

    enable 'CrossOrigin', origins => qr{^https://.*\.example\.com$};

    $app;
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
     -v http://localhost:5000/

# Test actual request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -X POST \
     -d '{"test":"data"}' \
     -v http://localhost:5000/
```

### 2. Test with Perl

```perl
#!/usr/bin/env perl
use HTTP::Tiny;

my $http = HTTP::Tiny->new;

# Test CORS request
my $response = $http->get(
    'http://localhost:5000/',
    {
        headers => {
            'Origin' => 'https://example.com',
        }
    }
);

print "Status: $response->{status}\n";
print "Allow-Origin: ", $response->{headers}{'access-control-allow-origin'} // 'none', "\n";
print "Vary: ", $response->{headers}{vary} // 'none', "\n";
```

### 3. Automated Testing

```perl
# t/cors.t
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $app = ...; # Your PSGI app

test_psgi $app, sub {
    my $cb = shift;

    # Test allowed origin
    my $res = $cb->(GET '/',
        Origin => 'https://example.com'
    );
    is $res->header('Access-Control-Allow-Origin'),
       'https://example.com',
       'Allowed origin accepted';

    # Test disallowed origin
    $res = $cb->(GET '/',
        Origin => 'https://evil.com'
    );
    ok !$res->header('Access-Control-Allow-Origin'),
       'Disallowed origin rejected';

    # Test preflight
    $res = $cb->(OPTIONS '/',
        Origin => 'https://example.com',
        'Access-Control-Request-Method' => 'POST'
    );
    is $res->code, 204, 'Preflight returns 204';
    like $res->header('Access-Control-Allow-Methods'),
         qr/POST/,
         'POST method allowed';
};

done_testing;
```

---

## Priority

**LOW PRIORITY**

**Justification:**
- Niche audience (Perl/PSGI users)
- Good middleware exists
- Legacy systems primarily
- Lower impact than mainstream technologies

**Impact:** Low - Small but dedicated Perl community

**Effort:** Low - Simple configuration examples

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Add security warning about wildcard
- [ ] Show specific origin configuration
- [ ] Add link to Plack::Middleware::CrossOrigin docs
- [ ] Link to [#152](https://github.com/monsur/enable-cors.org/issues/152)

### Short-term Actions (High Priority)
- [ ] Add full configuration example
- [ ] Show regex-based origin matching
- [ ] Include credentials configuration
- [ ] Add configuration parameter table

### Medium-term Actions
- [ ] Add testing examples
- [ ] Show framework integration (Dancer2, Mojolicious)
- [ ] Document deployment considerations
- [ ] Add path-specific CORS example

### Long-term Actions
- [ ] Create troubleshooting guide
- [ ] Add performance tips
- [ ] Document caching strategies

---

## Related Resources

### Official Documentation
- [Plack::Middleware::CrossOrigin on MetaCPAN](https://metacpan.org/pod/Plack::Middleware::CrossOrigin)
- [Plack Documentation](https://metacpan.org/pod/Plack)
- [PSGI Specification](https://metacpan.org/pod/PSGI)

### Package Installation
```bash
# CPAN
cpan Plack::Middleware::CrossOrigin

# Debian/Ubuntu
apt-get install libplack-middleware-crossorigin-perl

# cpanm
cpanm Plack::Middleware::CrossOrigin
```

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Additional Resources
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Plack GitHub](https://github.com/plack/Plack)

### Related enable-cors.org Pages
- [CGI CORS Configuration](server_cgi.html) - Legacy Perl CGI approach
- [Apache CORS](server_apache.html) - Often used with mod_perl

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
