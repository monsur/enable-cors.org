# CORS Implementation Analysis: ColdFusion

**File Reference:** `/server_coldfusion.html`
**Technology:** Adobe ColdFusion
**Analysis Date:** January 2025
**Status:** Medium Priority

---

## Current Implementation

Simple header setting using cfheader tag:

**Tag-based:**
```coldfusion
<cfheader name="Access-Control-Allow-Origin" value="*">
```

**Script-based:**
```coldfusion
cfheader( name="Access-Control-Allow-Origin", value="*");
```

**Pre-CF11:**
```coldfusion
var response = getPageContext().getResponse();
response.setHeader("Access-Control-Allow-Origin","*");
```

---

## Issues Identified

### Critical
- **C1**: Wildcard only, no validation examples
- **C2**: No preflight OPTIONS handling
- **C3**: Very minimal implementation

### High
- **H1**: No complete example showing real-world usage
- **H2**: Missing Vary header
- **H3**: Shows old CF syntax without modernalternatives

### Medium
- **M1**: No credentials configuration
- **M2**: No error handling
- **M3**: Missing CF2016+/2018+ modern approaches

---

## General Security Best Practices

### 1. Origin Validation
Must validate origins from whitelist:

```coldfusion
<cfscript>
allowedOrigins = ["https://example.com", "https://app.example.com"];
requestOrigin = cgi.HTTP_ORIGIN;

if (arrayFind(allowedOrigins, requestOrigin)) {
    cfheader(name="Access-Control-Allow-Origin", value=requestOrigin);
    cfheader(name="Vary", value="Origin");
}
</cfscript>
```

### 2. Preflight Request Handling
Must handle OPTIONS requests:

```coldfusion
<cfif cgi.REQUEST_METHOD == "OPTIONS">
    <cfheader name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS">
    <cfheader name="Access-Control-Allow-Headers" value="Content-Type, Authorization">
    <cfheader name="Access-Control-Max-Age" value="86400">
    <cfheader statusCode="204" statusText="No Content">
    <cfabort>
</cfif>
```

### 3. Credentials
```coldfusion
<cfheader name="Access-Control-Allow-Credentials" value="true">
```

### 4. Vary Header
```coldfusion
<cfheader name="Vary" value="Origin">
```

---

## Recommended Improvements

### Complete Modern Implementation (CF11+)

```coldfusion
<cfscript>
// CORS Configuration Component
component {
    variables.allowedOrigins = [
        'https://example.com',
        'https://app.example.com'
    ];

    public void function enableCORS() {
        var requestOrigin = cgi.HTTP_ORIGIN ?: '';

        // Validate origin
        if (arrayFind(variables.allowedOrigins, requestOrigin)) {
            cfheader(name="Access-Control-Allow-Origin", value=requestOrigin);
            cfheader(name="Access-Control-Allow-Credentials", value="true");
            cfheader(name="Vary", value="Origin");
        }

        // Handle preflight
        if (cgi.REQUEST_METHOD == "OPTIONS") {
            cfheader(name="Access-Control-Allow-Methods", value="GET, POST, PUT, DELETE, OPTIONS");
            cfheader(name="Access-Control-Allow-Headers", value="Content-Type, Authorization");
            cfheader(name="Access-Control-Max-Age", value="86400");
            cfheader(statusCode="204", statusText="No Content");
            abort;
        }
    }
}

// Usage
cors = new CORSHandler();
cors.enableCORS();

// Your application logic here
writeOutput(serializeJSON({
    'status': 'success',
    'message': 'CORS enabled'
}));
</cfscript>
```

### Tag-Based Implementation

```coldfusion
<!--- cors.cfm - Include at top of API pages --->
<cfscript>
allowedOrigins = ["https://example.com", "https://app.example.com"];
requestOrigin = cgi.HTTP_ORIGIN ?: "";

if (arrayFind(allowedOrigins, requestOrigin)) {
    cfheader(name="Access-Control-Allow-Origin", value=requestOrigin);
    cfheader(name="Vary", value="Origin");
}
</cfscript>

<cfif cgi.REQUEST_METHOD eq "OPTIONS">
    <cfheader name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS">
    <cfheader name="Access-Control-Allow-Headers" value="Content-Type, Authorization">
    <cfheader name="Access-Control-Max-Age" value="86400">
    <cfheader statusCode="204" statusText="No Content">
    <cfabort>
</cfif>
```

### Application.cfc Integration

```coldfusion
component {
    this.name = "MyApp";

    public boolean function onRequestStart(string targetPage) {
        // Enable CORS for API routes
        if (findNoCase("/api/", arguments.targetPage)) {
            enableCORS();
        }
        return true;
    }

    private void function enableCORS() {
        var allowedOrigins = [
            'https://example.com',
            'https://app.example.com'
        ];
        var origin = cgi.HTTP_ORIGIN ?: '';

        if (arrayFind(allowedOrigins, origin)) {
            cfheader(name="Access-Control-Allow-Origin", value=origin);
            cfheader(name="Vary", value="Origin");
        }

        if (cgi.REQUEST_METHOD == "OPTIONS") {
            cfheader(name="Access-Control-Allow-Methods", value="GET, POST, PUT, DELETE");
            cfheader(name="Access-Control-Max-Age", value="86400");
            cfheader(statusCode="204");
            abort;
        }
    }
}
```

---

## Technology-Specific Considerations

### ColdFusion Versions
- **CF11+**: Modern script syntax, use cfheader() function
- **CF10 and earlier**: Use getPageContext().getResponse()
- **CF2016+**: Better HTTP handling, modern features
- **Lucee**: Open-source alternative, similar syntax

### Performance
```coldfusion
<cfscript>
// Cache origin validation
application.corsCache = application.corsCache ?: {};

if (!structKeyExists(application.corsCache, requestOrigin)) {
    application.corsCache[requestOrigin] = arrayFind(allowedOrigins, requestOrigin);
}
</cfscript>
```

### REST API Integration
```coldfusion
component rest="true" restpath="/api" {
    remote any function getData() httpmethod="GET" restpath="/data" {
        enableCORS();
        return {"data": "value"};
    }

    private void function enableCORS() {
        // CORS logic here
    }
}
```

---

## Testing Instructions

### Test with curl
```bash
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     -v http://your-cf-server.com/api/endpoint.cfm
```

### Test in Browser
```javascript
fetch('http://your-cf-server.com/api/endpoint.cfm', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  credentials: 'include',
  body: JSON.stringify({test: 'data'})
}).then(r => r.json()).then(console.log);
```

---

## Priority

**MEDIUM PRIORITY**

ColdFusion is still used in enterprise environments but has declining marketshare. Current documentation is very minimal and needs comprehensive examples.

---

## Implementation Checklist

### Immediate
- [ ] Add security warning about wildcard
- [ ] Show complete implementation with validation
- [ ] Add preflight handling
- [ ] Include Vary header

### Short-term
- [ ] Add Application.cfc integration
- [ ] Show modern CF11+ syntax
- [ ] Include credentials example
- [ ] Add testing instructions

### Medium-term
- [ ] Document REST API integration
- [ ] Add performance considerations
- [ ] Show Lucee compatibility

---

## Related Resources

### Official Documentation
- [ColdFusion Documentation](https://helpx.adobe.com/coldfusion/home.html)
- [Lucee Documentation](https://docs.lucee.org/)

### Related enable-cors.org Pages
- [Apache CORS](server_apache.html) - Often runs ColdFusion
- [IIS CORS](server_iis7.html) - Windows ColdFusion deployment

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
