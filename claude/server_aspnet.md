# CORS Implementation Analysis: ASP.NET

**File Reference:** `/server_aspnet.html`
**Technology:** ASP.NET / ASP.NET Web API
**Analysis Date:** January 2025
**Status:** High Priority - Missing ASP.NET Core

---

## Current Implementation

Shows three approaches:

**Simple:**
```csharp
Response.AppendHeader("Access-Control-Allow-Origin", "*");
```

**Web API 2:**
```csharp
[EnableCors(origins: "http://example.com", headers: "*", methods: "*")]
public class TestController : ApiController {
    // Controller methods...
}
```

**Global:**
```csharp
config.EnableCors(new EnableCorsAttribute("http://example.com", "*", "*"));
```

---

## Issues Identified

### Critical
- **C1**: No ASP.NET Core examples (current framework)
- **C2**: Web API 2 is old (.NET Framework in maintenance mode)
- **C3**: Uses wildcard methods/headers `*` ([#152](https://github.com/monsur/enable-cors.org/issues/152))

### High
- **H1**: No origin validation logic shown
- **H2**: Missing Vary header
- **H3**: Thinktecture library references may be outdated

---

## General Security Best Practices

### 1-4. Standard CORS Practices
See other analysis files for detailed security practices ([#146](https://github.com/monsur/enable-cors.org/issues/146), [#152](https://github.com/monsur/enable-cors.org/issues/152)).

---

## Recommended Improvements

### ASP.NET Core 6.0+ (Recommended for New Projects)

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowSpecificOrigins",
        policy =>
        {
            policy.WithOrigins("https://example.com", "https://app.example.com")
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials()
                  .SetPreflightMaxAge(TimeSpan.FromDays(1));
        });

    // Named policy for specific endpoints
    options.AddPolicy("APIPolicy",
        policy =>
        {
            policy.WithOrigins("https://example.com")
                  .WithMethods("GET", "POST", "PUT", "DELETE")
                  .WithHeaders("Content-Type", "Authorization")
                  .SetPreflightMaxAge(TimeSpan.FromDays(1));
        });
});

var app = builder.Build();

// Use CORS globally
app.UseCors("AllowSpecificOrigins");

// Or per-endpoint
app.MapGet("/api/data", () => new { message = "CORS enabled" })
   .RequireCors("APIPolicy");

app.Run();
```

### ASP.NET Core - Controller-Based

```csharp
// Startup.cs or Program.cs
services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy",
        builder => builder
            .WithOrigins("https://example.com", "https://app.example.com")
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

// Controller
[Route("api/[controller]")]
[EnableCors("CorsPolicy")]
public class DataController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new { data = "value" });
    }
}
```

### ASP.NET Web API 2 (Legacy) - Improved

```csharp
// WebApiConfig.cs
public static void Register(HttpConfiguration config)
{
    var cors = new EnableCorsAttribute(
        origins: "https://example.com,https://app.example.com",
        headers: "Content-Type,Authorization",
        methods: "GET,POST,PUT,DELETE",
        SupportsCredentials = true
    );
    config.EnableCors(cors);
}

// Controller with specific CORS
[EnableCors(
    origins: "https://example.com,https://app.example.com",
    headers: "Content-Type,Authorization",
    methods: "GET,POST,PUT,DELETE",
    SupportsCredentials = true
)]
public class TestController : ApiController
{
    public IHttpActionResult Get()
    {
        return Ok(new { data = "value" });
    }
}
```

### Dynamic Origin Validation (ASP.NET Core)

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("DynamicOrigins",
        builder => builder
            .SetIsOriginAllowed(origin =>
            {
                // Check against database or config
                var allowedOrigins = GetAllowedOriginsFromConfig();
                return allowedOrigins.Contains(origin);
            })
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
});

List<string> GetAllowedOriginsFromConfig()
{
    return new List<string>
    {
        "https://example.com",
        "https://app.example.com"
    };
}
```

---

## Technology-Specific Considerations

### .NET Framework vs .NET Core/.NET 6+
- **.NET Framework**: In maintenance mode, use Web API 2 CORS
- **.NET Core/.NET 6+**: Current platform, use built-in CORS middleware

### Middleware Order (ASP.NET Core)
```csharp
// Correct order
app.UseRouting();
app.UseCors("PolicyName"); // CORS between routing and endpoints
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
```

### IIS Integration
When hosting in IIS, configure either in:
1. web.config (IIS level) - See [server_iis7.html](server_iis7.html)
2. Application code (recommended for ASP.NET Core)

Don't configure in both places - application-level takes precedence.

---

## Testing Instructions

```bash
# Test with curl
curl -H "Origin: https://example.com" \
     -X OPTIONS \
     -v https://your-api.com/api/endpoint

# Test with .NET HttpClient
var client = new HttpClient();
client.DefaultRequestHeaders.Add("Origin", "https://example.com");
var response = await client.GetAsync("https://your-api.com/api/data");
```

---

## Priority

**HIGH PRIORITY** - Popular framework, missing current version (ASP.NET Core)

---

## Implementation Checklist

### Immediate
- [ ] Add ASP.NET Core 6.0+ examples first
- [ ] Add note that .NET Framework is in maintenance mode
- [ ] Remove wildcard methods/headers from examples
- [ ] Add origin validation

### Short-term
- [ ] Show dynamic origin validation
- [ ] Document middleware order
- [ ] Add testing examples
- [ ] Include credentials configuration

---

## Related Resources

### Official Documentation
- [ASP.NET Core CORS](https://docs.microsoft.com/en-us/aspnet/core/security/cors)
- [Web API 2 CORS](https://docs.microsoft.com/en-us/aspnet/web-api/overview/security/enabling-cross-origin-requests-in-web-api)

### Related GitHub Issues
- [#152](https://github.com/monsur/enable-cors.org/issues/152), [#146](https://github.com/monsur/enable-cors.org/issues/146)

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Status:** Ready for Implementation
