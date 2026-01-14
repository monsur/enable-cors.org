# CORS Implementation Analysis: Spring Boot (Kotlin)
**File:** `server_spring-boot_kotlin.html`

---

## Current Implementation

**Technology:** Spring Boot with Kotlin (WebFlux)
**Approach:** External GitHub Gist reference

**Current Documentation:**
- Links to external Gist for code
- Focuses on WebFlux (reactive) approach only
- No inline code in documentation

---

## Issues Identified

### Critical
- ❌ **No inline code** - relies on external GitHub Gist which may disappear or change
- ❌ External dependency is a maintenance risk

### High Priority
- ❌ Only shows WebFlux (reactive) approach, not Spring MVC
- ❌ No explanation of the code
- ❌ Missing origin validation example
- ❌ No security warnings

### Medium Priority
- ⚠️ No mention of `@CrossOrigin` annotation approach
- ⚠️ Missing Spring Security CORS integration
- ⚠️ No environment-based configuration example

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using `Access-Control-Allow-Origin: *` allows any website to access your API. The CORS specification only allows a single origin value in the `Access-Control-Allow-Origin` header ([#146](https://github.com/monsur/enable-cors.org/issues/146)).

**Why This Matters:** Spring Boot makes CORS easy, but secure configuration requires explicit origin whitelisting.

### 2. Preflight Request Handling

Spring Boot automatically handles OPTIONS preflight requests when CORS is properly configured.

### 3. Credentials and Authentication

When using credentials (cookies, HTTP auth):
- CANNOT use wildcard `*` for origin
- MUST specify exact origins
- MUST set `allowCredentials = true`

### 4. Multiple Configuration Approaches

Spring Boot provides three ways to configure CORS:
1. Global configuration (WebMvcConfigurer or CorsWebFilter)
2. Per-controller with `@CrossOrigin` annotation
3. Per-method with `@CrossOrigin` annotation

---

## Recommended Improvements

### Include Inline Code Examples

**Method 1: Spring Boot WebFlux (Reactive)**

```kotlin
// For Spring WebFlux (reactive stack)
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.reactive.CorsWebFilter
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource

@Configuration
class CorsConfig {
    @Bean
    fun corsWebFilter(): CorsWebFilter {
        val corsConfig = CorsConfiguration().apply {
            // Specify allowed origins (NOT wildcard)
            allowedOrigins = listOf(
                "https://example.com",
                "https://app.example.com"
            )
            
            // Allowed HTTP methods
            allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "OPTIONS")
            
            // Allowed headers
            allowedHeaders = listOf("Content-Type", "Authorization")
            
            // Enable credentials
            allowCredentials = true
            
            // Preflight cache duration (seconds)
            maxAge = 86400L
        }

        val source = UrlBasedCorsConfigurationSource().apply {
            registerCorsConfiguration("/**", corsConfig)
        }

        return CorsWebFilter(source)
    }
}
```

**Method 2: Spring MVC (Non-Reactive)**

```kotlin
// For Spring MVC (traditional servlet stack)
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class CorsConfig : WebMvcConfigurer {
    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/api/**")
            .allowedOrigins(
                "https://example.com",
                "https://app.example.com"
            )
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("Content-Type", "Authorization")
            .allowCredentials(true)
            .maxAge(86400)
    }
}
```

**Method 3: Controller-Level with @CrossOrigin**

```kotlin
import org.springframework.web.bind.annotation.*

// Per-controller CORS
@RestController
@RequestMapping("/api")
@CrossOrigin(
    origins = ["https://example.com", "https://app.example.com"],
    methods = [
        RequestMethod.GET,
        RequestMethod.POST,
        RequestMethod.PUT,
        RequestMethod.DELETE
    ],
    allowedHeaders = ["Content-Type", "Authorization"],
    allowCredentials = "true",
    maxAge = 86400
)
class ApiController {
    
    @GetMapping("/data")
    fun getData(): Map<String, String> {
        return mapOf("message" to "CORS enabled")
    }
    
    // Override CORS for specific method
    @CrossOrigin(origins = ["https://public.example.com"])
    @GetMapping("/public")
    fun getPublicData(): Map<String, String> {
        return mapOf("message" to "Public endpoint")
    }
}
```

**Method 4: Method-Level @CrossOrigin**

```kotlin
@RestController
@RequestMapping("/api")
class ApiController {
    
    // CORS only on this specific method
    @CrossOrigin(
        origins = ["https://example.com"],
        allowCredentials = "true"
    )
    @PostMapping("/secure")
    fun secureEndpoint(@RequestBody data: Map<String, Any>): Map<String, String> {
        return mapOf("status" to "success")
    }
    
    // No CORS on this method
    @GetMapping("/internal")
    fun internalEndpoint(): Map<String, String> {
        return mapOf("message" to "Internal only")
    }
}
```

**Method 5: With Spring Security**

```kotlin
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.web.SecurityFilterChain
import org.springframework.web.cors.CorsConfiguration
import org.springframework.web.cors.CorsConfigurationSource
import org.springframework.web.cors.UrlBasedCorsConfigurationSource

@Configuration
@EnableWebSecurity
class SecurityConfig {
    
    @Bean
    fun securityFilterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .cors { cors ->
                cors.configurationSource(corsConfigurationSource())
            }
            .csrf { it.disable() }
            .authorizeHttpRequests { auth ->
                auth.requestMatchers("/public/**").permitAll()
                    .anyRequest().authenticated()
            }
        
        return http.build()
    }
    
    @Bean
    fun corsConfigurationSource(): CorsConfigurationSource {
        val configuration = CorsConfiguration().apply {
            allowedOrigins = listOf(
                "https://example.com",
                "https://app.example.com"
            )
            allowedMethods = listOf("GET", "POST", "PUT", "DELETE", "OPTIONS")
            allowedHeaders = listOf("Authorization", "Content-Type")
            allowCredentials = true
            maxAge = 86400L
        }
        
        return UrlBasedCorsConfigurationSource().apply {
            registerCorsConfiguration("/**", configuration)
        }
    }
}
```

**Method 6: Environment-Based Configuration**

```kotlin
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.CorsRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class CorsConfig(
    @Value("\${cors.allowed-origins}")
    private val allowedOrigins: List<String>
) : WebMvcConfigurer {
    
    override fun addCorsMappings(registry: CorsRegistry) {
        registry.addMapping("/api/**")
            .allowedOrigins(*allowedOrigins.toTypedArray())
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("Content-Type", "Authorization")
            .allowCredentials(true)
            .maxAge(86400)
    }
}
```

In `application.yml`:
```yaml
cors:
  allowed-origins:
    - https://example.com
    - https://app.example.com

# Or with profiles
---
spring:
  config:
    activate:
      on-profile: production

cors:
  allowed-origins:
    - https://example.com

---
spring:
  config:
    activate:
      on-profile: development

cors:
  allowed-origins:
    - http://localhost:3000
    - http://localhost:5173
```

---

## Spring Boot/Kotlin Specific Considerations

### 1. WebFlux vs MVC

**WebFlux (Reactive):**
- Use `CorsWebFilter` bean
- For reactive, non-blocking applications
- Use `org.springframework.web.cors.reactive.*` imports

**MVC (Traditional):**
- Implement `WebMvcConfigurer`
- For servlet-based applications
- Use `org.springframework.web.servlet.config.annotation.*` imports

**How to tell which you're using:**
```kotlin
// If you have spring-boot-starter-webflux
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-webflux")
}
// Use WebFlux approach

// If you have spring-boot-starter-web
dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
}
// Use MVC approach
```

### 2. Configuration Precedence

When multiple CORS configurations exist:
1. **Method-level `@CrossOrigin`** - Highest priority
2. **Controller-level `@CrossOrigin`** - Medium priority
3. **Global configuration** - Lowest priority

More specific configurations override general ones.

### 3. Spring Security Integration

When using Spring Security, configure CORS in Security Config:

```kotlin
http.cors { cors ->
    cors.configurationSource(corsConfigurationSource())
}
```

**Important:** Place CORS configuration BEFORE `.csrf()` and other security configs.

### 4. Kotlin DSL Advantages

Kotlin's DSL makes configuration more readable:

```kotlin
// Clean Kotlin DSL
val corsConfig = CorsConfiguration().apply {
    allowedOrigins = listOf("https://example.com")
    allowedMethods = listOf("GET", "POST")
    allowCredentials = true
}

// vs Java
CorsConfiguration corsConfig = new CorsConfiguration();
corsConfig.setAllowedOrigins(Arrays.asList("https://example.com"));
corsConfig.setAllowedMethods(Arrays.asList("GET", "POST"));
corsConfig.setAllowCredentials(true);
```

### 5. Testing CORS in Spring Boot

```kotlin
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.junit.jupiter.api.Test

@SpringBootTest
@AutoConfigureMockMvc
class CorsTest(
    @Autowired private val mockMvc: MockMvc
) {
    
    @Test
    fun `should allow whitelisted origin`() {
        mockMvc.perform(
            get("/api/data")
                .header("Origin", "https://example.com")
        )
            .andExpect(status().isOk)
            .andExpect(
                header().string(
                    "Access-Control-Allow-Origin",
                    "https://example.com"
                )
            )
    }
    
    @Test
    fun `should reject non-whitelisted origin`() {
        mockMvc.perform(
            get("/api/data")
                .header("Origin", "https://evil.com")
        )
            .andExpect(status().isOk)
            .andExpect(
                header().doesNotExist("Access-Control-Allow-Origin")
            )
    }
    
    @Test
    fun `should handle preflight request`() {
        mockMvc.perform(
            options("/api/data")
                .header("Origin", "https://example.com")
                .header("Access-Control-Request-Method", "POST")
                .header("Access-Control-Request-Headers", "Content-Type")
        )
            .andExpect(status().isOk)
            .andExpect(
                header().string(
                    "Access-Control-Allow-Methods",
                    containsString("POST")
                )
            )
    }
}
```

---

## Testing Your Configuration

### 1. Test with curl

```bash
# Test actual request
curl -H "Origin: https://example.com" \
     -H "Content-Type: application/json" \
     http://localhost:8080/api/data \
     -v

# Test preflight
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     http://localhost:8080/api/data \
     -v
```

### 2. Enable Spring Boot Logging

In `application.yml`:
```yaml
logging:
  level:
    org.springframework.web.cors: DEBUG
    org.springframework.security.web.cors: DEBUG
```

### 3. Run Automated Tests

```bash
./gradlew test
# or
./mvnw test
```

### 4. Browser DevTools

1. Open browser console
2. Check Network tab for CORS headers
3. Look for preflight OPTIONS requests
4. Check Console for CORS errors

---

## Priority

**High** - Spring Boot is extremely popular, and the current external Gist reference is unreliable. Inline code is essential.

---

## Implementation Checklist

- [ ] Include inline code for WebFlux approach
- [ ] Include inline code for MVC approach
- [ ] Show `@CrossOrigin` annotation usage (controller and method level)
- [ ] Add Spring Security integration example
- [ ] Include environment-based configuration
- [ ] Add security warnings about wildcards
- [ ] Explain WebFlux vs MVC differences
- [ ] Document configuration precedence
- [ ] Include Kotlin DSL advantages
- [ ] Add automated testing examples
- [ ] Show logging configuration
- [ ] Remove dependency on external Gist
- [ ] Add link to Spring Boot CORS documentation

---

## Related Resources

- [Spring Boot CORS Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/web.html#web.servlet.spring-mvc.cors)
- [Spring Framework CORS Support](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-cors)
- [Spring Security CORS](https://docs.spring.io/spring-security/reference/servlet/integrations/cors.html)
- [Kotlin Spring Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/kotlin.html)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #146: Multi-origin support](https://github.com/monsur/enable-cors.org/issues/146)
- [GitHub Issue #152: Security concerns](https://github.com/monsur/enable-cors.org/issues/152)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** ✅ COMPLETED - Implemented January 2025
