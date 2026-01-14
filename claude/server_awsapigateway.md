# CORS Implementation Analysis: AWS API Gateway
**File:** `server_awsapigateway.html`

---

## Current Implementation

**Technology:** AWS API Gateway
**Approach:** Manual console configuration with step-by-step instructions

**Current Documentation:**
- Manual, error-prone console clicks
- Mentions jQuery specifically (outdated reference)
- Uses deprecated testing tool (client.cors-api.appspot.com)
- No Infrastructure-as-Code examples

---

## Issues Identified

### Critical
- ❌ **Outdated approach** - AWS has significantly improved CORS support
- ❌ Very manual, error-prone process (10+ steps per method)
- ❌ Missing information about REST API vs HTTP API differences

### High Priority
- ❌ No mention of AWS CDK, CloudFormation, or Terraform
- ❌ Uses deprecated testing tool
- ❌ Mentions jQuery specifically (irrelevant to CORS)
- ❌ "Enable CORS" button behavior not documented

### Medium Priority
- ⚠️ No origin validation guidance
- ⚠️ Missing security warnings about wildcards
- ⚠️ No Lambda integration example
- ⚠️ Complex manual steps prone to errors

---

## General Security Best Practices

### 1. Origin Validation (Critical)

**Problem:** Using `Access-Control-Allow-Origin: *` allows any website to access your API. The CORS specification only allows a single origin value ([#146](https://github.com/monsur/enable-cors.org/issues/146)).

**Why This Matters:** API Gateway often protects sensitive business APIs. Wildcard CORS defeats AWS's security model.

### 2. REST API vs HTTP API

**Critical Distinction:**
- **HTTP API**: Simpler, cheaper, better CORS support (recommended for new projects)
- **REST API**: More features, more complex CORS configuration

**Recommendation:** Use HTTP API unless you need REST API-specific features (API keys, usage plans, request validation).

### 3. Preflight Request Handling

API Gateway must handle OPTIONS preflight requests. Configuration varies significantly between REST and HTTP APIs.

### 4. Infrastructure as Code

**Always use IaC** for API Gateway CORS:
- Reduces errors
- Version controlled
- Repeatable
- Auditable

---

## Recommended Improvements

### Add Important Notice

```html
<div class="info-box" style="background: #d1ecf1; border: 1px solid #0c5460; padding: 15px; margin: 20px 0;">
  <strong>⚠️ AWS API Gateway has two types:</strong>
  <ul>
    <li><strong>HTTP API</strong> - Simpler, cheaper, better CORS support (recommended for new projects)</li>
    <li><strong>REST API</strong> - More features but complex CORS configuration</li>
  </ul>
  <p>Choose HTTP API unless you need REST API-specific features like API keys or request validation.</p>
</div>
```

### Modern Approaches

#### 1. HTTP API with AWS Console (Simplest)

**Steps:**
1. Open AWS API Gateway console
2. Create or select HTTP API
3. Go to **CORS** settings
4. Configure:
   - **Access-Control-Allow-Origin**: `https://example.com`
   - **Access-Control-Allow-Methods**: `GET,POST,PUT,DELETE`
   - **Access-Control-Allow-Headers**: `Content-Type,Authorization`
   - **Access-Control-Max-Age**: `86400`
   - **Access-Control-Allow-Credentials**: Yes (if needed)
5. Save

**That's it!** HTTP API handles OPTIONS automatically.

#### 2. AWS SAM / CloudFormation (Recommended)

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  # HTTP API (Simple, Recommended)
  MyHttpApi:
    Type: AWS::Serverless::HttpApi
    Properties:
      CorsConfiguration:
        AllowOrigins:
          - https://example.com
          - https://app.example.com
        AllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
        AllowHeaders:
          - Content-Type
          - Authorization
        MaxAge: 86400
        AllowCredentials: true

  # REST API (More Complex)
  MyRestApi:
    Type: AWS::Serverless::Api
    Properties:
      StageName: prod
      Cors:
        AllowOrigin: "'https://example.com'"
        AllowHeaders: "'Content-Type,Authorization'"
        AllowMethods: "'GET,POST,PUT,DELETE,OPTIONS'"
        MaxAge: "'86400'"
        AllowCredentials: true

  # Lambda Function
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: python3.11
      Handler: index.handler
      Events:
        ApiEvent:
          Type: HttpApi
          Properties:
            ApiId: !Ref MyHttpApi
            Path: /data
            Method: get
```

#### 3. AWS CDK (TypeScript)

```typescript
import * as cdk from 'aws-cdk-lib';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as apigatewayv2 from '@aws-cdk/aws-apigatewayv2-alpha';
import * as lambda from 'aws-cdk-lib/aws-lambda';

export class CorsStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string) {
    super(scope, id);

    // HTTP API (Recommended - Simpler)
    const httpApi = new apigatewayv2.HttpApi(this, 'HttpApi', {
      apiName: 'my-http-api',
      corsPreflight: {
        allowOrigins: [
          'https://example.com',
          'https://app.example.com'
        ],
        allowMethods: [
          apigatewayv2.CorsHttpMethod.GET,
          apigatewayv2.CorsHttpMethod.POST,
          apigatewayv2.CorsHttpMethod.PUT,
          apigatewayv2.CorsHttpMethod.DELETE
        ],
        allowHeaders: ['Content-Type', 'Authorization'],
        maxAge: cdk.Duration.days(1),
        allowCredentials: true
      }
    });

    // REST API (More Features)
    const restApi = new apigateway.RestApi(this, 'RestApi', {
      restApiName: 'my-rest-api',
      defaultCorsPreflightOptions: {
        allowOrigins: [
          'https://example.com',
          'https://app.example.com'
        ],
        allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
        allowHeaders: ['Content-Type', 'Authorization'],
        maxAge: cdk.Duration.days(1),
        allowCredentials: true
      }
    });

    // Lambda integration
    const handler = new lambda.Function(this, 'Handler', {
      runtime: lambda.Runtime.PYTHON_3_11,
      code: lambda.Code.fromAsset('lambda'),
      handler: 'index.handler'
    });

    // Add Lambda to HTTP API
    const integration = new apigatewayv2.HttpLambdaIntegration(
      'Integration',
      handler
    );

    httpApi.addRoutes({
      path: '/data',
      methods: [apigatewayv2.HttpMethod.GET],
      integration: integration
    });
  }
}
```

#### 4. Terraform

```hcl
# HTTP API (Recommended)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "my-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "https://example.com",
      "https://app.example.com"
    ]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 86400
    allow_credentials = true
  }
}

# REST API
resource "aws_api_gateway_rest_api" "rest_api" {
  name = "my-rest-api"
}

resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://example.com'"
  }
}
```

#### 5. Lambda Function CORS (Fallback)

If API Gateway CORS doesn't meet your needs, handle in Lambda:

```python
# Python Lambda
import json

def lambda_handler(event, context):
    # Get origin from request
    origin = event['headers'].get('origin', '')
    
    # Validate origin
    allowed_origins = [
        'https://example.com',
        'https://app.example.com'
    ]
    
    cors_headers = {}
    if origin in allowed_origins:
        cors_headers = {
            'Access-Control-Allow-Origin': origin,
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Max-Age': '86400',
            'Vary': 'Origin'
        }
    
    # Handle preflight
    if event['requestContext']['http']['method'] == 'OPTIONS':
        return {
            'statusCode': 204,
            'headers': cors_headers,
            'body': ''
        }
    
    # Handle actual request
    return {
        'statusCode': 200,
        'headers': {
            **cors_headers,
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'message': 'Success'})
    }
```

```javascript
// Node.js Lambda
exports.handler = async (event) => {
    const origin = event.headers.origin || '';
    
    const allowedOrigins = [
        'https://example.com',
        'https://app.example.com'
    ];
    
    const corsHeaders = {};
    if (allowedOrigins.includes(origin)) {
        corsHeaders['Access-Control-Allow-Origin'] = origin;
        corsHeaders['Access-Control-Allow-Methods'] = 'GET,POST,PUT,DELETE,OPTIONS';
        corsHeaders['Access-Control-Allow-Headers'] = 'Content-Type,Authorization';
        corsHeaders['Access-Control-Max-Age'] = '86400';
        corsHeaders['Vary'] = 'Origin';
    }
    
    // Handle preflight
    if (event.requestContext.http.method === 'OPTIONS') {
        return {
            statusCode: 204,
            headers: corsHeaders,
            body: ''
        };
    }
    
    // Handle actual request
    return {
        statusCode: 200,
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message: 'Success' })
    };
};
```

---

## AWS-Specific Considerations

### 1. HTTP API vs REST API Feature Comparison

| Feature | HTTP API | REST API |
|---------|----------|----------|
| **CORS Configuration** | Simple, built-in | Complex, manual OPTIONS |
| **Price** | Cheaper (~70% less) | More expensive |
| **Latency** | Lower | Higher |
| **API Keys** | ❌ No | ✅ Yes |
| **Usage Plans** | ❌ No | ✅ Yes |
| **Request Validation** | ❌ No | ✅ Yes |
| **AWS WAF** | ✅ Yes | ✅ Yes |
| **Lambda Authorizers** | ✅ Yes | ✅ Yes |

**Recommendation:** Use HTTP API unless you need REST API-specific features.

### 2. Common Pitfalls

**Pitfall 1: Forgetting to Deploy**
```bash
# After making CORS changes in console, you MUST deploy
aws apigateway create-deployment \
  --rest-api-id YOUR_API_ID \
  --stage-name prod
```

**Pitfall 2: Missing CORS on Error Responses**

REST API only adds CORS headers to 200 responses by default. Add to error responses:

```yaml
# SAM template
GatewayResponses:
  DEFAULT_4XX:
    ResponseParameters:
      gatewayresponse.header.Access-Control-Allow-Origin: "'https://example.com'"
      gatewayresponse.header.Access-Control-Allow-Headers: "'Content-Type'"
```

**Pitfall 3: Credentials with Wildcard**

This combination is INVALID:
```yaml
AllowOrigin: "'*'"
AllowCredentials: true  # ❌ ERROR!
```

Must use specific origin:
```yaml
AllowOrigin: "'https://example.com'"
AllowCredentials: true  # ✅ OK
```

### 3. Testing API Gateway CORS

```bash
# Test HTTP API
curl -H "Origin: https://example.com" \
     https://api-id.execute-api.region.amazonaws.com/data \
     -v

# Test preflight
curl -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     https://api-id.execute-api.region.amazonaws.com/data \
     -v

# Test with AWS CLI
aws apigatewayv2 get-api --api-id YOUR_API_ID
```

### 4. Monitoring CORS Issues

Use CloudWatch Logs:
```bash
# Enable logging
aws apigatewayv2 update-stage \
  --api-id YOUR_API_ID \
  --stage-name '$default' \
  --access-log-settings '{"DestinationArn":"arn:aws:logs:...","Format":"$context.requestId"}'

# View logs
aws logs tail /aws/apigateway/YOUR_API_ID --follow
```

---

## Testing Your Configuration

### 1. Browser DevTools

1. Open browser console
2. Make request to API Gateway endpoint
3. Check Network tab for CORS headers
4. Verify preflight OPTIONS request
5. Check Console for CORS errors

### 2. Postman/Thunder Client

Configure request with Origin header:
```
Origin: https://example.com
```

Check response for CORS headers.

### 3. Automated Testing

```javascript
// Jest test
test('API Gateway CORS', async () => {
  const response = await fetch(API_URL, {
    method: 'GET',
    headers: {
      'Origin': 'https://example.com'
    }
  });
  
  expect(response.headers.get('Access-Control-Allow-Origin'))
    .toBe('https://example.com');
});
```

---

## Priority

**High** - AWS API Gateway is extremely popular. Current documentation is outdated and error-prone.

---

## Implementation Checklist

- [ ] Add prominent notice about HTTP API vs REST API
- [ ] Recommend HTTP API for new projects
- [ ] Show AWS SAM/CloudFormation examples
- [ ] Show AWS CDK examples (TypeScript)
- [ ] Show Terraform examples
- [ ] Include Lambda CORS handling
- [ ] Document common pitfalls
- [ ] Update manual console instructions for current AWS UI
- [ ] Remove deprecated testing tool reference
- [ ] Remove jQuery reference (irrelevant)
- [ ] Add security warnings about wildcards
- [ ] Show credentials configuration
- [ ] Include monitoring/logging setup
- [ ] Add comprehensive testing instructions

---

## Related Resources

- [AWS HTTP API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [AWS REST API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api.html)
- [AWS API Gateway CORS](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [MDN: CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [GitHub Issue #146: Multi-origin support](https://github.com/monsur/enable-cors.org/issues/146)
- [GitHub Issue #152: Security concerns](https://github.com/monsur/enable-cors.org/issues/152)

---

**Analysis Date:** January 2025
**Analyst:** Claude Code
**Status:** Ready for implementation
