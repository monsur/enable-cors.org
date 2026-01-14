# CORS Implementation Analysis: Google App Engine

**File Reference:** `/server_appengine.html`
**Technology:** Google App Engine (Python, Java, Go)
**Analysis Date:** January 2025
**Status:** ✅ COMPLETED - Implemented January 2025

---

## Current Implementation

Shows old App Engine syntax for three languages:

**Python (outdated):**
```python
class CORSEnabledHandler(webapp.RequestHandler):
  def get(self):
    self.response.headers.add_header("Access-Control-Allow-Origin", "*")
    self.response.headers['Content-Type'] = 'text/csv'
    self.response.out.write(self.dump_csv())
```

**Java:**
```java
public void doGet(HttpServletRequest req, HttpServletResponse resp) {
  resp.addHeader("Access-Control-Allow-Origin", "*");
  resp.addHeader("Content-Type", "text/csv");
  resp.getWriter().append(csvString);
}
```

**Go:**
```go
func doGet(w http.ResponseWriter, r *http.Request) {
  w.Header().Add("Access-Control-Allow-Origin", "*")
  w.Header().Add("Content-Type", "text/csv")
  fmt.Fprintf(w, csvData)
}
```

---

## Issues Identified

### Critical
- **C1**: Python shows `webapp.RequestHandler` - deprecated, very old syntax
- **C2**: Uses wildcard `*` in all examples ([#152](https://github.com/monsur/enable-cors.org/issues/152))
- **C3**: No distinction between App Engine Standard vs Flexible
- **C4**: No preflight OPTIONS handling in any language

### High
- **H1**: Missing modern App Engine Standard 2nd gen (Python 3.7+) approach
- **H2**: No origin validation in any example
- **H3**: Missing Vary header
- **H4**: Doesn't mention modern frameworks (Flask, Django for Python)

### Medium
- **M1**: No credentials configuration
- **M2**: No environment considerations (dev vs prod)
- **M3**: Limited explanation of App Engine versions/generations

---

## General Security Best Practices

### 1. Origin Validation
Must validate origins ([#146](https://github.com/monsur/enable-cors.org/issues/146)):

All languages need to check origin against whitelist and echo back if allowed.

### 2. Preflight Handling
Must handle OPTIONS requests in all languages.

### 3. Vary Header
Must include `Vary: Origin` when origin varies.

---

## Recommended Improvements

### Modern Python (App Engine Standard, Python 3.9+)

**With Flask (Recommended):**
```python
# main.py
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Secure CORS configuration
CORS(app, origins=[
    'https://example.com',
    'https://app.example.com'
], supports_credentials=True)

@app.route('/api/data')
def get_data():
    return {'data': 'value'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

**app.yaml:**
```yaml
runtime: python39

handlers:
- url: /.*
  script: auto
```

**Manual Implementation:**
```python
# main.py
from flask import Flask, request

app = Flask(__name__)

ALLOWED_ORIGINS = [
    'https://example.com',
    'https://app.example.com'
]

@app.before_request
def handle_cors():
    origin = request.headers.get('Origin', '')

    if origin in ALLOWED_ORIGINS:
        @app.after_request
        def add_cors_headers(response):
            response.headers['Access-Control-Allow-Origin'] = origin
            response.headers['Access-Control-Allow-Credentials'] = 'true'
            response.headers['Vary'] = 'Origin'
            return response

    if request.method == 'OPTIONS':
        response = app.make_response('')
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        response.headers['Access-Control-Max-Age'] = '86400'
        return response, 204

@app.route('/api/data')
def get_data():
    return {'data': 'value'}
```

### Modern Go (App Engine Standard, Go 1.18+)

```go
// main.go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
)

var allowedOrigins = []string{
    "https://example.com",
    "https://app.example.com",
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        origin := r.Header.Get("Origin")

        // Validate origin
        for _, allowed := range allowedOrigins {
            if origin == allowed {
                w.Header().Set("Access-Control-Allow-Origin", origin)
                w.Header().Set("Access-Control-Allow-Credentials", "true")
                w.Header().Set("Vary", "Origin")
                break
            }
        }

        // Handle preflight
        if r.Method == "OPTIONS" {
            w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
            w.Header().Set("Access-Control-Max-Age", "86400")
            w.WriteHeader(http.StatusNoContent)
            return
        }

        next(w, r)
    }
}

func dataHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{
        "message": "CORS enabled",
    })
}

func main() {
    http.HandleFunc("/api/data", corsMiddleware(dataHandler))

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    fmt.Printf("Server listening on port %s\n", port)
    http.ListenAndServe(":"+port, nil)
}
```

**app.yaml:**
```yaml
runtime: go118

env_variables:
  CORS_ORIGINS: "https://example.com,https://app.example.com"
```

### Modern Java (App Engine Standard, Java 11+)

**With Spring Boot:**
```java
// Application.java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("https://example.com", "https://app.example.com")
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("Content-Type", "Authorization")
                    .allowCredentials(true)
                    .maxAge(86400);
            }
        };
    }
}
```

**Servlet Filter:**
```java
@WebFilter(urlPatterns = {"/api/*"})
public class CorsFilter implements Filter {
    private static final String[] ALLOWED_ORIGINS = {
        "https://example.com",
        "https://app.example.com"
    };

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;

        String origin = request.getHeader("Origin");

        // Validate origin
        if (origin != null && Arrays.asList(ALLOWED_ORIGINS).contains(origin)) {
            response.addHeader("Access-Control-Allow-Origin", origin);
            response.addHeader("Access-Control-Allow-Credentials", "true");
            response.addHeader("Vary", "Origin");
        }

        // Handle preflight
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.addHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            response.addHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
            response.addHeader("Access-Control-Max-Age", "86400");
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
            return;
        }

        chain.doFilter(req, res);
    }
}
```

---

## Technology-Specific Considerations

### App Engine Generations

**Python:**
- Standard 1st gen: Python 2.7 (deprecated)
- Standard 2nd gen: Python 3.7+ (current) - Use Flask/Django
- Flexible: Any Python version - containerized

**Go:**
- Standard 1st gen: Go 1.11-1.14 (legacy)
- Standard 2nd gen: Go 1.15+ (current)

**Java:**
- Standard: Java 11, 17 (current)
- Flexible: Any Java version

### App Engine vs Cloud Run
For new projects, consider Cloud Run:
- More flexible
- Better container support
- Similar pricing
- Standard Docker approach

### Environment Configuration
```yaml
# app.yaml
env_variables:
  CORS_ALLOWED_ORIGINS: "https://example.com,https://app.example.com"
```

Access in code:
```python
import os
origins = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')
```

---

## Testing Instructions

### Local Testing
```bash
# Python
python main.py

# Go
go run main.go

# Java
mvn appengine:run
```

### Test CORS
```bash
curl -H "Origin: https://example.com" \
     -v https://your-project.appspot.com/api/endpoint
```

---

## Priority

**HIGH PRIORITY**

App Engine is popular GCP service but documentation shows very outdated syntax. Needs comprehensive update.

**Impact:** High - Many GCP users
**Effort:** Medium - Need examples for all three languages

---

## Implementation Checklist

### Immediate
- [ ] Add note about outdated syntax
- [ ] Show modern Python 3.7+ with Flask
- [ ] Update Go example to Go 1.18+
- [ ] Update Java to Java 11+ with Spring Boot
- [ ] Add security warnings

### Short-term
- [ ] Distinguish Standard vs Flexible
- [ ] Add origin validation to all examples
- [ ] Include preflight handling
- [ ] Add Vary header
- [ ] Show environment configuration

### Medium-term
- [ ] Document App Engine generations
- [ ] Add Cloud Run comparison
- [ ] Include deployment examples
- [ ] Add testing instructions

---

## Related Resources

### Official Documentation
- [App Engine Python 3 Runtime](https://cloud.google.com/appengine/docs/standard/python3)
- [App Engine Go Runtime](https://cloud.google.com/appengine/docs/standard/go)
- [App Engine Java Runtime](https://cloud.google.com/appengine/docs/standard/java-gen2)

### Related GitHub Issues
- [#152 - Security concerns about wildcard CORS](https://github.com/monsur/enable-cors.org/issues/152)
- [#146 - CORS Origin must support array of values](https://github.com/monsur/enable-cors.org/issues/146)

### Related enable-cors.org Pages
- [Flask](server_flask.html) - Recommended for Python
- [Spring Boot](server_spring-boot_kotlin.html) - Java framework

---

**Analysis Prepared By:** Claude Sonnet 4.5
**Last Updated:** January 2025
**Document Version:** 1.0
**Status:** ✅ Implementation Complete
