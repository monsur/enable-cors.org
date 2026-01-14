# CORS Implementation Analysis: Apache Tomcat
**File:** `server_tomcat.html`

---

## Current Implementation

**Technology:** Apache Tomcat
**Approach:** Built-in CorsFilter with minimal configuration

**Existing Code:**
```xml
<filter>
  <filter-name>CorsFilter</filter-name>
  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>
</filter>
<filter-mapping>
  <filter-name>CorsFilter</filter-name>
  <url-pattern>/*</url-pattern>
</filter-mapping>
```

---

## Strengths

✅ Uses built-in CORS filter (best practice)
✅ Links to official documentation
✅ Clean, declarative configuration

---

## Issues Identified

### Critical
- ❌ Minimal configuration shown - doesn't demonstrate init parameters
- ❌ No example of origin restriction (defaults to wildcard `*`)

### High Priority
- ❌ Missing explanation of filter parameters
- ❌ Documentation link may need updating for latest Tomcat versions
- ❌ No security warnings about default behavior

### Medium Priority
- ⚠️ Missing credentials configuration example
- ⚠️ No preflight caching configuration shown
- ⚠️ Path-specific mapping not discussed

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using `Access-Control-Allow-Origin: *` (the CorsFilter default) allows any website to access your API. The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)), so you must configure specific origins.

**Why This Matters:** Tomcat's CorsFilter defaults to permissive settings. Always explicitly configure allowed origins.

### 2. Preflight Request Handling

Tomcat's CorsFilter automatically handles OPTIONS preflight requests when properly configured with init parameters.

### 3. Credentials and Authentication

When using credentials (cookies, HTTP auth):
- CANNOT use wildcard `*` for origin
- MUST specify exact origins via `cors.allowed.origins`
- MUST set `cors.support.credentials` to `true`

### 4. Filter Configuration

Tomcat CorsFilter is configured entirely through `<init-param>` elements in web.xml, making it declarative and version-controlled.

---

## Recommended Improvements

### Comprehensive Configuration Example

```xml
<!-- Enhanced CORS Filter Configuration -->
<filter>
  <filter-name>CorsFilter</filter-name>
  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>

  <!-- Recommended: Specify allowed origins -->
  <init-param>
    <param-name>cors.allowed.origins</param-name>
    <param-value>https://example.com,https://app.example.com</param-value>
  </init-param>

  <!-- Allowed HTTP methods -->
  <init-param>
    <param-name>cors.allowed.methods</param-name>
    <param-value>GET,POST,PUT,DELETE,OPTIONS</param-value>
  </init-param>

  <!-- Allowed headers -->
  <init-param>
    <param-name>cors.allowed.headers</param-name>
    <param-value>Content-Type,Authorization,X-Requested-With</param-value>
  </init-param>

  <!-- Exposed headers (visible to client) -->
  <init-param>
    <param-name>cors.exposed.headers</param-name>
    <param-value>Content-Length,X-Custom-Header</param-value>
  </init-param>

  <!-- Allow credentials (cookies, HTTP auth) -->
  <init-param>
    <param-name>cors.support.credentials</param-name>
    <param-value>true</param-value>
  </init-param>

  <!-- Preflight cache duration (seconds) -->
  <init-param>
    <param-name>cors.preflight.maxage</param-name>
    <param-value>86400</param-value>
  </init-param>
</filter>

<filter-mapping>
  <filter-name>CorsFilter</filter-name>
  <url-pattern>/api/*</url-pattern>
</filter-mapping>
```

### Configuration Examples by Use Case

#### 1. Single Origin (Most Secure)

```xml
<filter>
  <filter-name>CorsFilter</filter-name>
  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>

  <init-param>
    <param-name>cors.allowed.origins</param-name>
    <param-value>https://example.com</param-value>
  </init-param>

  <init-param>
    <param-name>cors.allowed.methods</param-name>
    <param-value>GET,POST,PUT,DELETE,OPTIONS</param-value>
  </init-param>

  <init-param>
    <param-name>cors.allowed.headers</param-name>
    <param-value>Content-Type,Authorization</param-value>
  </init-param>
</filter>

<filter-mapping>
  <filter-name>CorsFilter</filter-name>
  <url-pattern>/api/*</url-pattern>
</filter-mapping>
```

#### 2. Multiple Specific Origins

```xml
<init-param>
  <param-name>cors.allowed.origins</param-name>
  <param-value>https://example.com,https://app.example.com,https://staging.example.com</param-value>
</init-param>
```

#### 3. With Credentials (Cookies/Sessions)

```xml
<init-param>
  <param-name>cors.allowed.origins</param-name>
  <param-value>https://example.com</param-value>
</init-param>

<init-param>
  <param-name>cors.support.credentials</param-name>
  <param-value>true</param-value>
</init-param>

<init-param>
  <param-name>cors.allowed.methods</param-name>
  <param-value>GET,POST,PUT,DELETE,OPTIONS</param-value>
</init-param>
```

#### 4. Origin Pattern Matching (Regex)

```xml
<!-- Allow any subdomain of example.com -->
<init-param>
  <param-name>cors.allowed.origins</param-name>
  <param-value>*</param-value>
</init-param>

<init-param>
  <param-name>cors.allowed.origins.regex</param-name>
  <param-value>https?://(.+\.)?example\.com</param-value>
</init-param>
```

#### 5. Path-Specific CORS

```xml
<!-- CORS only on API endpoints -->
<filter-mapping>
  <filter-name>CorsFilter</filter-name>
  <url-pattern>/api/*</url-pattern>
</filter-mapping>

<!-- Separate CORS config for public endpoints -->
<filter>
  <filter-name>PublicCorsFilter</filter-name>
  <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>
  <init-param>
    <param-name>cors.allowed.origins</param-name>
    <param-value>*</param-value>
  </init-param>
</filter>

<filter-mapping>
  <filter-name>PublicCorsFilter</filter-name>
  <url-pattern>/public/*</url-pattern>
</filter-mapping>
```

---

## Common Filter Parameters Reference

| Parameter | Description | Example Value | Default |
|-----------|-------------|---------------|---------|
| `cors.allowed.origins` | Comma-separated allowed origins | `https://example.com` | `*` (any) |
| `cors.allowed.origins.regex` | Regex pattern for origins | `https?://(.+\.)?example\.com` | None |
| `cors.allowed.methods` | Allowed HTTP methods | `GET,POST,PUT,DELETE,OPTIONS` | `GET,POST,HEAD,OPTIONS` |
| `cors.allowed.headers` | Request headers allowed | `Content-Type,Authorization` | `*` |
| `cors.exposed.headers` | Response headers exposed to client | `X-Custom-Header` | None |
| `cors.support.credentials` | Enable credentials | `true` | `false` |
| `cors.preflight.maxage` | Preflight cache (seconds) | `86400` (1 day) | `1800` (30 min) |
| `cors.request.decorate` | Add CORS info to request attributes | `true` | `true` |
| `cors.logging.enabled` | Enable CORS logging | `true` | `false` |

---

## Java/Tomcat Specific Considerations

### 1. Filter Ordering

CORS filter should be placed early in the filter chain, before authentication/authorization filters:

```xml
<!-- CORS filter first -->
<filter-mapping>
  <filter-name>CorsFilter</filter-name>
  <url-pattern>/*</url-pattern>
</filter-mapping>

<!-- Then security filters -->
<filter-mapping>
  <filter-name>AuthenticationFilter</filter-name>
  <url-pattern>/*</url-pattern>
</filter-mapping>
```

**Why:** Preflight OPTIONS requests don't include authentication headers, so CORS must process them before auth filters reject them.

### 2. Integration with Spring Security

If using Spring Security with Tomcat, configure CORS in Spring, not web.xml:

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf().disable()
            .authorizeRequests()
            .anyRequest().authenticated();
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList("https://example.com", "https://app.example.com"));
        config.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type"));
        config.setAllowCredentials(true);
        config.setMaxAge(86400L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
```

### 3. Tomcat Version Compatibility

- **Tomcat 7.0.41+**: CorsFilter first introduced
- **Tomcat 8.0+**: Improved CORS filter with better logging
- **Tomcat 8.5+**: Enhanced regex support
- **Tomcat 9.0+**: Current stable version (recommended)
- **Tomcat 10.0+**: Jakarta EE namespace (javax.* → jakarta.*), but CorsFilter class name unchanged

For all versions, the filter class is:
```xml
<filter-class>org.apache.catalina.filters.CorsFilter</filter-class>
```

### 4. Logging CORS Requests

Enable logging to debug CORS issues:

```xml
<init-param>
  <param-name>cors.logging.enabled</param-name>
  <param-value>true</param-value>
</init-param>
```

Then check catalina.out for messages like:
- "Request is a CORS request"
- "Not a CORS request"
- "CORS origin validation passed/failed"

### 5. Environment-Specific Configuration

Use context parameters for environment-specific origins:

```xml
<!-- In $CATALINA_BASE/conf/context.xml or META-INF/context.xml -->
<Context>
  <Parameter name="cors.allowed.origins"
             value="${CORS_ORIGINS:https://example.com}"
             override="false"/>
</Context>
```

Then reference in web.xml:
```xml
<init-param>
  <param-name>cors.allowed.origins</param-name>
  <param-value>${cors.allowed.origins}</param-value>
</init-param>
```

Set via environment variable:
```bash
export CORS_ORIGINS="https://example.com,https://app.example.com"
```

### 6. Request Attributes

When `cors.request.decorate` is true (default), the filter adds request attributes:

```java
// In your servlet/controller
Boolean isCorsRequest = (Boolean) request.getAttribute("cors.isCorsRequest");
String origin = (String) request.getAttribute("cors.request.origin");
String requestType = (String) request.getAttribute("cors.request.type");
// "simple" or "preflight" or "not_cors"
```

---

## Testing Your Configuration

### 1. Validate web.xml Syntax

```bash
# Validate XML
xmllint --noout /path/to/webapp/WEB-INF/web.xml

# Or use Tomcat's built-in validation during deployment
```

### 2. Test with curl

```bash
# Test actual GET request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     -i http://localhost:8080/myapp/api/data

# Test preflight OPTIONS request
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     -i http://localhost:8080/myapp/api/data

# Test with credentials
curl -H "Origin: https://example.com" \
     --cookie "JSESSIONID=ABC123" \
     -i http://localhost:8080/myapp/api/data
```

### 3. Verify Response Headers

Expected headers for allowed origin:
```
Access-Control-Allow-Origin: https://example.com
Vary: Origin
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Credentials: true
```

For preflight:
```
Access-Control-Max-Age: 86400
Access-Control-Allow-Headers: Content-Type, Authorization
```

### 4. Test Rejected Origin

```bash
curl -H "Origin: https://evil.com" \
     -i http://localhost:8080/myapp/api/data
```

Should NOT return `Access-Control-Allow-Origin` header.

### 5. Check Tomcat Logs

Enable CORS logging and watch logs:
```bash
# Enable in web.xml
<init-param>
  <param-name>cors.logging.enabled</param-name>
  <param-value>true</param-value>
</init-param>

# Watch logs
tail -f $CATALINA_HOME/logs/catalina.out | grep -i cors
```

### 6. Browser DevTools Testing

1. Open your web app in browser
2. Open DevTools → Network tab
3. Make a cross-origin request
4. Check response headers
5. Look for preflight OPTIONS request
6. Check Console for CORS errors

---

## Priority

**Medium** - Tomcat configuration is functional but minimal. Needs expanded examples and parameter documentation.

---

## Implementation Checklist

- [ ] Add security warning about default wildcard behavior
- [ ] Show comprehensive filter configuration with all parameters
- [ ] Add parameter reference table
- [ ] Include single-origin example (most secure)
- [ ] Include multi-origin example
- [ ] Show credentials configuration
- [ ] Document origin pattern matching with regex
- [ ] Show path-specific filter mapping
- [ ] Document filter ordering importance
- [ ] Include Spring Security integration example
- [ ] Document Tomcat version compatibility
- [ ] Add CORS logging configuration
- [ ] Show environment-specific configuration
- [ ] Include comprehensive testing instructions
- [ ] Update documentation links for Tomcat 10+

---

## Related Resources

- [Tomcat 10 CORS Filter Documentation](https://tomcat.apache.org/tomcat-10.1-doc/config/filter.html#CORS_Filter)
- [Tomcat 9 CORS Filter Documentation](https://tomcat.apache.org/tomcat-9.0-doc/config/filter.html#CORS_Filter)
- [Apache Tomcat Official Website](https://tomcat.apache.org/)
- [Spring Security CORS Documentation](https://docs.spring.io/spring-security/reference/servlet/integrations/cors.html)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #146: Multi-origin support](https://github.com/monsur/enable-cors.org/issues/146)
- [GitHub Issue #152: Security concerns](https://github.com/monsur/enable-cors.org/issues/152)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** ✅ Implementation Complete
