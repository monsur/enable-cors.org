# CORS Implementation Analysis: IIS7

**File Reference:** `/server_iis7.html`
**Technology:** Internet Information Services 7+
**Analysis Date:** January 2025
**Status:** ✅ COMPLETED - Implemented January 2025

---

## Current Implementation

The current IIS7 documentation provides:

1. **Basic web.config approach** - Simple XML configuration to add CORS headers via `<customHeaders>`
2. **CORS Module reference** - Link to official Microsoft CORS Module documentation
3. **Wildcard origin** - Uses `Access-Control-Allow-Origin: *` without warnings

### Current Code Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
 <system.webServer>
   <httpProtocol>
     <customHeaders>
       <add name="Access-Control-Allow-Origin" value="*" />
     </customHeaders>
   </httpProtocol>
 </system.webServer>
</configuration>
```

**Strengths:**
- Clean, straightforward XML configuration
- References official Microsoft documentation
- Works with IIS7+

---

## Issues Identified

### Critical Priority

**C1. Insecure Wildcard Configuration**
- Uses `Access-Control-Allow-Origin: *` without security warnings
- No explanation of security implications
- No secure alternative provided
- **Impact:** Allows any website to access resources
- **Related Issue:** [#152](https://github.com/monsur/enable-cors.org/issues/152) - Security concerns about wildcard CORS

### High Priority

**H1. Missing Preflight OPTIONS Handling**
- No example of handling OPTIONS requests
- Required for non-simple CORS requests
- Missing handler configuration
- **Impact:** Complex requests with custom headers will fail

**H2. No Origin Validation Example**
- Only shows wildcard configuration
- Doesn't demonstrate how to validate specific origins in web.config
- No guidance for programmatic validation
- **Impact:** Users don't know how to secure their CORS configuration

**H3. Missing Vary Header**
- No `Vary: Origin` header in example
- **Impact:** Can cause caching issues when responses vary by origin
- **Related Issue:** [#164](https://github.com/monsur/enable-cors.org/issues/164) - Modern security headers

### Medium Priority

**M1. Limited Configuration Options**
- Doesn't show `Access-Control-Allow-Methods` configuration
- Missing `Access-Control-Allow-Headers` example
- No `Access-Control-Max-Age` for preflight caching
- **Impact:** Users need to manually discover additional configuration options

**M2. CORS Module Link May Be Outdated**
- Microsoft documentation URLs frequently change
- No alternative references provided
- **Impact:** Link rot could leave users without proper documentation

### Low Priority

**L1. No Integration Example**
- Doesn't show how web.config CORS interacts with ASP.NET code-level CORS
- No guidance on when to use which approach
- **Impact:** Potential conflicts between IIS and application-level CORS

**L2. Missing IIS Version Information**
- Applies to IIS7, IIS8, IIS10, but no version-specific notes
- **Impact:** Users may not know if this applies to their IIS version

---

## General Security Best Practices

### 1. Origin Validation
**CRITICAL:** The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)). You cannot use a comma-separated list. To support multiple trusted origins, you must implement origin validation logic.

**Secure Approach:**
```xml
<!-- Static configuration for single origin -->
<add name="Access-Control-Allow-Origin" value="https://example.com" />
<add name="Vary" value="Origin" />
```

For multiple origins, use programmatic validation (see ASP.NET examples) or the IIS CORS Module.

### 2. Preflight Request Handling
OPTIONS requests must be properly handled to support non-simple CORS requests:

```xml
<handlers>
  <add name="OptionsHandler" verb="OPTIONS" path="*" type="System.Web.DefaultHttpHandler" />
</handlers>
```

### 3. Credentials and Authentication
When using credentials (cookies, HTTP auth):
- CANNOT use wildcard `*` for origin
- MUST specify exact origin
- MUST include `Access-Control-Allow-Credentials: true`

```xml
<!-- INVALID with credentials -->
<add name="Access-Control-Allow-Origin" value="*" />
<add name="Access-Control-Allow-Credentials" value="true" />

<!-- VALID with credentials -->
<add name="Access-Control-Allow-Origin" value="https://example.com" />
<add name="Access-Control-Allow-Credentials" value="true" />
<add name="Vary" value="Origin" />
```

### 4. Caching Considerations (Vary Header)
When CORS headers change based on the origin, always include the `Vary` header:

```xml
<add name="Vary" value="Origin" />
```

This prevents cache poisoning where one origin receives another origin's cached response.

---

## Recommended Improvements

### Enhanced web.config Example

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <httpProtocol>
      <customHeaders>
        <!-- SECURE: Specify allowed origin instead of wildcard -->
        <add name="Access-Control-Allow-Origin" value="https://example.com" />
        <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS" />
        <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization" />
        <add name="Access-Control-Max-Age" value="86400" />
        <add name="Vary" value="Origin" />
      </customHeaders>
    </httpProtocol>

    <!-- Handle OPTIONS preflight requests -->
    <handlers>
      <add name="OptionsHandler" verb="OPTIONS" path="*"
           type="System.Web.DefaultHttpHandler"
           resourceType="Unspecified"
           requireAccess="None" />
    </handlers>

    <!-- Return 204 for OPTIONS requests -->
    <rewrite>
      <rules>
        <rule name="CORS Preflight" stopProcessing="true">
          <match url=".*" />
          <conditions>
            <add input="{REQUEST_METHOD}" pattern="^OPTIONS$" />
          </conditions>
          <action type="CustomResponse" statusCode="204" statusReason="No Content" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

### Using IIS CORS Module

For more sophisticated origin validation, use the official IIS CORS Module:

```xml
<system.webServer>
  <cors enabled="true" failUnlistedOrigins="true">
    <add origin="https://example.com"
         allowed="true"
         allowCredentials="true"
         maxAge="86400">
      <allowHeaders>
        <add header="Content-Type" />
        <add header="Authorization" />
      </allowHeaders>
      <allowMethods>
        <add method="GET" />
        <add method="POST" />
        <add method="PUT" />
        <add method="DELETE" />
      </allowMethods>
      <exposeHeaders>
        <add header="Content-Length" />
        <add header="X-Custom-Header" />
      </exposeHeaders>
    </add>
    <add origin="https://app.example.com" allowed="true" />
  </cors>
</system.webServer>
```

### Security Warning to Add

Add a prominent warning box before the wildcard example:

```
⚠️ Security Warning: The example below uses Access-Control-Allow-Origin: * which
allows ANY website to access your resources. This is only appropriate for completely
public APIs. For most use cases, you should validate and whitelist specific origins.
```

### Note on Programmatic Validation

Add guidance for when to use application-level CORS:

```
Note: For dynamic origin validation based on database or business logic, consider
using ASP.NET application-level CORS instead of web.config. See the ASP.NET
documentation for examples.
```

---

## Technology-Specific Considerations

### IIS Version Compatibility
- **IIS 7.0+** - Custom headers work in all versions
- **IIS 8.5+** - CORS Module available as extension
- **IIS 10.0+** - Latest version with improved performance

### Integration with ASP.NET
**Precedence:** Application-level CORS (in ASP.NET code) takes precedence over web.config headers.

**Best Practice:**
- Use web.config for static CORS configuration
- Use ASP.NET code for dynamic origin validation
- Don't configure both unless you understand the interaction

### URL Rewrite Module
For preflight handling, the URL Rewrite Module must be installed:
```bash
# Available from Microsoft IIS Downloads
# Or via Web Platform Installer
```

### Performance Considerations
- Custom headers in web.config have minimal performance impact
- CORS Module provides better performance for complex validation
- Avoid checking origin in every request handler - use middleware

---

## Testing Instructions

### 1. Verify Basic CORS Headers

Use curl to test:
```bash
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     -v https://your-api.com/endpoint
```

Expected headers in response:
```
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
Vary: Origin
```

### 2. Test with Browser DevTools

1. Open browser DevTools (F12)
2. Go to Network tab
3. Make a cross-origin request
4. Check response headers for CORS headers
5. Look for OPTIONS preflight request (for non-simple requests)

### 3. Common CORS Errors to Check

**"No 'Access-Control-Allow-Origin' header is present"**
- Solution: Verify web.config is being read
- Check that IIS has restarted after configuration changes

**"The 'Access-Control-Allow-Origin' header contains multiple values"**
- Solution: Don't set CORS headers in both web.config and application code

**"Credential is not supported if CORS header is '*'"**
- Solution: Replace wildcard with specific origin

**"Method POST is not allowed by Access-Control-Allow-Methods"**
- Solution: Add POST to Access-Control-Allow-Methods in web.config

### 4. Verify web.config Loading

Check IIS logs to ensure web.config is being processed:
```
%SystemDrive%\inetpub\logs\LogFiles
```

---

## Priority

**HIGH PRIORITY**

**Justification:**
- Widely used web server platform
- Current example uses insecure wildcard configuration
- Missing critical preflight handling
- Easy to implement security improvements
- IIS users often less familiar with CORS than Apache/Nginx users

**Impact:** Medium to High - Many production IIS servers may be using insecure wildcard CORS

**Effort:** Low - Documentation updates and additional examples

---

## Implementation Checklist

### Immediate Actions (Critical)
- [ ] Add security warning about wildcard CORS before code example
- [ ] Show secure single-origin example first
- [ ] Add note about origin validation for multiple origins
- [ ] Link to [#152](https://github.com/monsur/enable-cors.org/issues/152) for context

### Short-term Actions (High Priority)
- [ ] Add preflight OPTIONS handling example
- [ ] Include `Vary: Origin` header in all examples
- [ ] Add complete web.config example with all headers
- [ ] Document IIS CORS Module configuration
- [ ] Add note about ASP.NET integration

### Medium-term Actions
- [ ] Create troubleshooting section for common IIS CORS issues
- [ ] Add example showing credentials configuration
- [ ] Document performance considerations
- [ ] Add version-specific notes for IIS 7/8/10

### Long-term Actions
- [ ] Create video tutorial for IIS CORS setup
- [ ] Add interactive configuration generator
- [ ] Document integration with Azure App Service
- [ ] Add examples for IIS on Nano Server

---

## Related Resources

### Official Documentation
- [Microsoft IIS CORS Module Configuration](https://docs.microsoft.com/en-us/iis/extensions/cors-module/cors-module-configuration-reference)
- [IIS Configuration Reference](https://docs.microsoft.com/en-us/iis/configuration/)
- [ASP.NET CORS Documentation](https://docs.microsoft.com/en-us/aspnet/web-api/overview/security/enabling-cross-origin-requests-in-web-api)

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)
- [#164 - Integration with modern security headers (COEP/COOP)](https://github.com/monsur/enable-cors.org/issues/164)

### Additional Resources
- [MDN Web Docs: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [IIS URL Rewrite Module](https://www.iis.net/downloads/microsoft/url-rewrite)
- [Web Platform Installer](https://www.microsoft.com/web/downloads/platform.aspx)

### Related enable-cors.org Pages
- [ASP.NET CORS Configuration](server_aspnet.html) - Application-level CORS
- [IIS 6 Configuration](server_iis6.html) - Legacy IIS (deprecated)

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** Ready for Implementation
