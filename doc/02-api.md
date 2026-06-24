# 智能商城 AI 助理平台接口文档

## 1. 文档说明

本文档定义智能商城 AI 助理平台的主要 REST API、SSE 流式接口和 MCP 能力清单。接口以中型练习项目为目标，字段可根据实际开发继续补充。

## 2. 通用约定

### 2.1 基础地址

```text
http://localhost:8080
```

### 2.2 鉴权方式

普通接口使用 Bearer Token。

```http
Authorization: Bearer <access_token>
```

开发阶段可使用模拟用户，生产化时接入 Spring Security 和 JWT。

### 2.3 通用响应结构

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {},
  "traceId": "b7a6d8f6f1b14c3c"
}
```

### 2.4 分页响应结构

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "records": [],
    "pageNo": 1,
    "pageSize": 20,
    "total": 100
  },
  "traceId": "b7a6d8f6f1b14c3c"
}
```

### 2.5 通用错误码

| 错误码 | 说明 |
| --- | --- |
| SUCCESS | 成功 |
| BAD_REQUEST | 请求参数错误 |
| UNAUTHORIZED | 未登录或 Token 无效 |
| FORBIDDEN | 无权限 |
| NOT_FOUND | 资源不存在 |
| CONFLICT | 业务状态冲突 |
| VALIDATION_FAILED | 参数校验失败 |
| AI_MODEL_ERROR | 模型调用失败 |
| AI_TOOL_ERROR | 工具调用失败 |
| RAG_RETRIEVAL_ERROR | 知识库检索失败 |
| MCP_SERVER_UNAVAILABLE | MCP 服务不可用 |
| INTERNAL_ERROR | 系统内部错误 |

## 3. 用户接口

### 3.1 用户登录

```http
POST /api/auth/login
```

请求体：

```json
{
  "username": "user001",
  "password": "123456"
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "accessToken": "mock-token",
    "expiresIn": 7200,
    "user": {
      "id": 1,
      "username": "user001",
      "displayName": "张三",
      "role": "CUSTOMER"
    }
  },
  "traceId": "trace-id"
}
```

### 3.2 查询当前用户

```http
GET /api/users/me
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1,
    "username": "user001",
    "displayName": "张三",
    "role": "CUSTOMER"
  },
  "traceId": "trace-id"
}
```

## 4. 商品接口

### 4.1 商品分页查询

```http
GET /api/products?pageNo=1&pageSize=20&keyword=耳机&categoryId=10&minPrice=100&maxPrice=500&tags=运动,防水
```

查询参数：

| 参数 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| pageNo | integer | 否 | 页码，默认 1 |
| pageSize | integer | 否 | 每页数量，默认 20 |
| keyword | string | 否 | 关键词 |
| categoryId | long | 否 | 分类 ID |
| brand | string | 否 | 品牌 |
| minPrice | decimal | 否 | 最低价格 |
| maxPrice | decimal | 否 | 最高价格 |
| tags | string | 否 | 逗号分隔标签 |

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "records": [
      {
        "id": 1001,
        "name": "X200 运动蓝牙耳机",
        "brand": "SoundPlus",
        "categoryId": 10,
        "categoryName": "蓝牙耳机",
        "minPrice": 299.00,
        "mainImageUrl": "https://example.com/x200.png",
        "tags": ["运动", "防水", "长续航"],
        "status": "ON_SALE"
      }
    ],
    "pageNo": 1,
    "pageSize": 20,
    "total": 1
  },
  "traceId": "trace-id"
}
```

### 4.2 商品详情

```http
GET /api/products/{productId}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1001,
    "name": "X200 运动蓝牙耳机",
    "brand": "SoundPlus",
    "categoryId": 10,
    "description": "适合跑步和通勤的无线蓝牙耳机。",
    "attributes": {
      "waterproof": "IPX5",
      "batteryLife": "32 小时",
      "noiseReduction": "ENC 通话降噪"
    },
    "skus": [
      {
        "id": 2001,
        "skuCode": "X200-BLACK",
        "name": "黑色",
        "price": 299.00,
        "stock": 100
      }
    ],
    "tags": ["运动", "防水", "长续航"],
    "status": "ON_SALE"
  },
  "traceId": "trace-id"
}
```

### 4.3 管理端新增商品

```http
POST /api/admin/products
```

请求体：

```json
{
  "name": "X200 运动蓝牙耳机",
  "brand": "SoundPlus",
  "categoryId": 10,
  "description": "适合跑步和通勤的无线蓝牙耳机。",
  "mainImageUrl": "https://example.com/x200.png",
  "tags": ["运动", "防水", "长续航"],
  "attributes": {
    "waterproof": "IPX5",
    "batteryLife": "32 小时"
  },
  "skus": [
    {
      "skuCode": "X200-BLACK",
      "name": "黑色",
      "price": 299.00,
      "stock": 100
    }
  ]
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "id": 1001
  },
  "traceId": "trace-id"
}
```

### 4.4 管理端更新商品

```http
PUT /api/admin/products/{productId}
```

请求体同新增商品。

### 4.5 商品上下架

```http
PATCH /api/admin/products/{productId}/status
```

请求体：

```json
{
  "status": "ON_SALE"
}
```

## 5. 订单接口

### 5.1 创建订单

```http
POST /api/orders
```

请求体：

```json
{
  "items": [
    {
      "skuId": 2001,
      "quantity": 1
    }
  ],
  "couponId": 3001,
  "receiver": {
    "name": "张三",
    "phone": "13800000000",
    "address": "上海市浦东新区示例路 1 号"
  },
  "remark": "工作日配送"
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "orderId": 5001,
    "orderNo": "202606230001",
    "payAmount": 279.00,
    "status": "PENDING_PAYMENT"
  },
  "traceId": "trace-id"
}
```

### 5.2 查询订单详情

```http
GET /api/orders/{orderNo}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "orderNo": "202606230001",
    "status": "SHIPPED",
    "payStatus": "PAID",
    "logisticsStatus": "IN_TRANSIT",
    "totalAmount": 299.00,
    "discountAmount": 20.00,
    "payAmount": 279.00,
    "items": [
      {
        "productId": 1001,
        "skuId": 2001,
        "productName": "X200 运动蓝牙耳机",
        "skuName": "黑色",
        "quantity": 1,
        "price": 299.00
      }
    ],
    "createdAt": "2026-06-23T10:00:00"
  },
  "traceId": "trace-id"
}
```

### 5.3 模拟支付

```http
POST /api/orders/{orderNo}/pay
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "orderNo": "202606230001",
    "status": "PAID"
  },
  "traceId": "trace-id"
}
```

### 5.4 取消订单

```http
POST /api/orders/{orderNo}/cancel
```

请求体：

```json
{
  "reason": "不想买了"
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "orderNo": "202606230001",
    "status": "CANCELED"
  },
  "traceId": "trace-id"
}
```

## 6. 优惠券接口

### 6.1 查询可用优惠券

```http
GET /api/coupons/available?productId=1001&skuId=2001
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "couponId": 3001,
      "name": "满 299 减 20",
      "type": "FULL_REDUCTION",
      "thresholdAmount": 299.00,
      "discountAmount": 20.00,
      "expiresAt": "2026-07-01T23:59:59"
    }
  ],
  "traceId": "trace-id"
}
```

### 6.2 计算最优价格

```http
POST /api/coupons/calculate-best-price
```

请求体：

```json
{
  "items": [
    {
      "skuId": 2001,
      "quantity": 1
    }
  ],
  "couponIds": [3001]
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "originalAmount": 299.00,
    "discountAmount": 20.00,
    "payAmount": 279.00,
    "appliedCoupons": [
      {
        "couponId": 3001,
        "name": "满 299 减 20",
        "discountAmount": 20.00
      }
    ]
  },
  "traceId": "trace-id"
}
```

## 7. 评论接口

### 7.1 新增评论

```http
POST /api/products/{productId}/reviews
```

请求体：

```json
{
  "orderNo": "202606230001",
  "skuId": 2001,
  "rating": 5,
  "content": "佩戴舒服，跑步不容易掉，续航不错。"
}
```

### 7.2 查询商品评论

```http
GET /api/products/{productId}/reviews?pageNo=1&pageSize=20
```

### 7.3 查询 AI 评论摘要

```http
GET /api/products/{productId}/reviews/ai-summary
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "summary": "用户普遍认可佩戴舒适度、续航和运动稳定性，少量用户认为低频音质一般。",
    "positivePoints": ["佩戴舒服", "续航长", "跑步稳定"],
    "negativePoints": ["低频表现一般"]
  },
  "traceId": "trace-id"
}
```

## 8. 售后接口

### 8.1 创建售后申请

```http
POST /api/after-sales
```

请求体：

```json
{
  "orderNo": "202606230001",
  "orderItemId": 6001,
  "type": "RETURN",
  "reason": "商品故障",
  "description": "使用 5 天后无法开机"
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "afterSalesNo": "AS202606230001",
    "status": "PENDING_REVIEW"
  },
  "traceId": "trace-id"
}
```

### 8.2 查询售后详情

```http
GET /api/after-sales/{afterSalesNo}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "afterSalesNo": "AS202606230001",
    "orderNo": "202606230001",
    "type": "RETURN",
    "status": "PENDING_REVIEW",
    "reason": "商品故障",
    "createdAt": "2026-06-23T11:00:00"
  },
  "traceId": "trace-id"
}
```

## 9. AI 对话接口

### 9.1 普通聊天

```http
POST /api/ai/chat
```

请求体：

```json
{
  "conversationId": "c_10001",
  "message": "我预算 500 元，想买跑步耳机，推荐几款。",
  "scene": "SHOPPING",
  "enableRag": true,
  "enableTools": true,
  "metadata": {
    "currentProductId": 1001
  }
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "conversationId": "c_10001",
    "messageId": "m_20001",
    "agent": "PRODUCT_ADVISOR",
    "content": "根据你的预算和跑步场景，我优先推荐以下几款...",
    "structuredResult": {
      "recommendations": [
        {
          "productId": 1001,
          "name": "X200 运动蓝牙耳机",
          "price": 299.00,
          "reason": "IPX5 防水，适合跑步，续航 32 小时。"
        }
      ]
    },
    "ragSources": [
      {
        "documentId": 9001,
        "chunkId": 9101,
        "title": "X200 商品说明书",
        "score": 0.86
      }
    ],
    "toolCalls": [
      {
        "toolName": "searchProducts",
        "status": "SUCCESS",
        "durationMs": 85
      }
    ]
  },
  "traceId": "trace-id"
}
```

### 9.2 流式聊天

```http
POST /api/ai/chat/stream
Accept: text/event-stream
```

请求体同普通聊天。

SSE 事件示例：

```text
event: agent
data: {"agent":"PRODUCT_ADVISOR"}

event: tool_call
data: {"toolName":"searchProducts","status":"STARTED"}

event: tool_call
data: {"toolName":"searchProducts","status":"SUCCESS","durationMs":85}

event: message_delta
data: {"content":"根据你的预算和跑步场景，"}

event: message_delta
data: {"content":"我推荐以下几款耳机。"}

event: done
data: {"messageId":"m_20001"}
```

### 9.3 查询会话列表

```http
GET /api/ai/conversations?pageNo=1&pageSize=20
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "records": [
      {
        "conversationId": "c_10001",
        "title": "跑步耳机推荐",
        "lastMessage": "我推荐以下几款耳机...",
        "updatedAt": "2026-06-23T11:30:00"
      }
    ],
    "pageNo": 1,
    "pageSize": 20,
    "total": 1
  },
  "traceId": "trace-id"
}
```

### 9.4 查询会话详情

```http
GET /api/ai/conversations/{conversationId}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "conversationId": "c_10001",
    "title": "跑步耳机推荐",
    "messages": [
      {
        "messageId": "m_10001",
        "role": "USER",
        "content": "我预算 500 元，想买跑步耳机，推荐几款。",
        "createdAt": "2026-06-23T11:29:00"
      },
      {
        "messageId": "m_20001",
        "role": "ASSISTANT",
        "content": "根据你的预算和跑步场景...",
        "agent": "PRODUCT_ADVISOR",
        "createdAt": "2026-06-23T11:29:05"
      }
    ]
  },
  "traceId": "trace-id"
}
```

### 9.5 用户反馈 AI 回复

```http
POST /api/ai/messages/{messageId}/feedback
```

请求体：

```json
{
  "rating": "UP",
  "reason": "推荐准确"
}
```

## 10. 知识库接口

### 10.1 上传知识文档

```http
POST /api/admin/knowledge/documents
Content-Type: multipart/form-data
```

表单字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| file | file | 是 | 文档文件 |
| title | string | 是 | 文档标题 |
| docType | string | 是 | PRODUCT_MANUAL、AFTER_SALES_POLICY、FAQ、PROMOTION_RULE |
| productId | long | 否 | 关联商品 |
| categoryId | long | 否 | 关联分类 |
| version | string | 否 | 文档版本 |

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "documentId": 9001,
    "status": "UPLOADED"
  },
  "traceId": "trace-id"
}
```

### 10.2 文档列表

```http
GET /api/admin/knowledge/documents?pageNo=1&pageSize=20&docType=FAQ&status=INDEXED
```

### 10.3 触发文档入库

```http
POST /api/admin/knowledge/documents/{documentId}/ingest
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "documentId": 9001,
    "status": "INDEXING"
  },
  "traceId": "trace-id"
}
```

### 10.4 删除知识文档

```http
DELETE /api/admin/knowledge/documents/{documentId}
```

### 10.5 RAG 检索测试

```http
POST /api/admin/knowledge/search-test
```

请求体：

```json
{
  "query": "耳机拆封后还能七天无理由吗？",
  "topK": 5,
  "similarityThreshold": 0.75,
  "filters": {
    "docType": "AFTER_SALES_POLICY",
    "categoryId": 10
  }
}
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "hits": [
      {
        "documentId": 9002,
        "chunkId": 9102,
        "title": "耳机类目售后政策",
        "contentPreview": "耳机类商品拆封后，如非质量问题...",
        "score": 0.88,
        "metadata": {
          "docType": "AFTER_SALES_POLICY",
          "categoryId": 10
        }
      }
    ]
  },
  "traceId": "trace-id"
}
```

## 11. 管理端 AI 日志接口

### 11.1 查询 Agent 执行日志

```http
GET /api/admin/ai/agent-traces?conversationId=c_10001&agent=PRODUCT_ADVISOR&pageNo=1&pageSize=20
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "records": [
      {
        "traceId": "trace-id",
        "conversationId": "c_10001",
        "agent": "PRODUCT_ADVISOR",
        "intent": "PRODUCT_RECOMMENDATION",
        "status": "SUCCESS",
        "durationMs": 1280,
        "createdAt": "2026-06-23T11:29:05"
      }
    ],
    "pageNo": 1,
    "pageSize": 20,
    "total": 1
  },
  "traceId": "trace-id"
}
```

### 11.2 查询工具调用日志

```http
GET /api/admin/ai/tool-invocations?toolName=searchProducts&status=SUCCESS&pageNo=1&pageSize=20
```

### 11.3 查询 RAG 命中日志

```http
GET /api/admin/ai/rag-hit-logs?conversationId=c_10001&pageNo=1&pageSize=20
```

### 11.4 查询模型调用日志

```http
GET /api/admin/ai/model-call-logs?modelName=gpt-4.1-mini&pageNo=1&pageSize=20
```

## 12. 管理端 Agent 配置接口

### 12.1 查询 Agent 列表

```http
GET /api/admin/ai/agents
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "agentCode": "ROUTER",
      "name": "Router Agent",
      "enabled": true,
      "description": "识别用户意图并路由到业务 Agent"
    },
    {
      "agentCode": "PRODUCT_ADVISOR",
      "name": "Product Advisor Agent",
      "enabled": true,
      "description": "负责商品推荐和商品对比"
    }
  ],
  "traceId": "trace-id"
}
```

### 12.2 更新 Agent 开关

```http
PATCH /api/admin/ai/agents/{agentCode}/status
```

请求体：

```json
{
  "enabled": true
}
```

## 13. MCP 管理接口

### 13.1 查询 MCP Server 列表

```http
GET /api/admin/mcp/servers
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "serverCode": "logistics-mcp",
      "name": "物流 MCP 服务",
      "transport": "HTTP",
      "endpoint": "http://localhost:8092/mcp",
      "status": "UP"
    }
  ],
  "traceId": "trace-id"
}
```

### 13.2 查询 MCP 工具列表

```http
GET /api/admin/mcp/tools
```

响应：

```json
{
  "code": "SUCCESS",
  "message": "OK",
  "data": [
    {
      "serverCode": "logistics-mcp",
      "toolName": "logistics.getTrace",
      "description": "查询物流轨迹",
      "enabled": true
    }
  ],
  "traceId": "trace-id"
}
```

## 14. MCP 工具能力清单

### 14.1 Order MCP Server

#### order.getStatus

输入：

```json
{
  "orderNo": "202606230001",
  "userId": 1
}
```

输出：

```json
{
  "orderNo": "202606230001",
  "status": "SHIPPED",
  "payStatus": "PAID",
  "logisticsNo": "SF123456789"
}
```

#### order.getAfterSalesStatus

输入：

```json
{
  "afterSalesNo": "AS202606230001",
  "userId": 1
}
```

输出：

```json
{
  "afterSalesNo": "AS202606230001",
  "status": "PENDING_REVIEW"
}
```

### 14.2 Logistics MCP Server

#### logistics.getTrace

输入：

```json
{
  "logisticsNo": "SF123456789"
}
```

输出：

```json
{
  "logisticsNo": "SF123456789",
  "status": "IN_TRANSIT",
  "estimatedDeliveryTime": "2026-06-25T18:00:00",
  "traces": [
    {
      "time": "2026-06-23T15:00:00",
      "location": "上海转运中心",
      "description": "快件已发出"
    }
  ]
}
```

#### logistics.estimateDelivery

输入：

```json
{
  "province": "上海",
  "city": "上海市",
  "carrier": "SF"
}
```

输出：

```json
{
  "estimatedDays": 2,
  "estimatedDeliveryTime": "2026-06-25T18:00:00"
}
```

### 14.3 Promotion MCP Server

#### promotion.calculateBestPrice

输入：

```json
{
  "userId": 1,
  "items": [
    {
      "skuId": 2001,
      "quantity": 1
    }
  ]
}
```

输出：

```json
{
  "originalAmount": 299.00,
  "discountAmount": 20.00,
  "payAmount": 279.00,
  "rules": ["满 299 减 20"]
}
```

#### promotion.getAvailableCoupons

输入：

```json
{
  "userId": 1,
  "skuId": 2001
}
```

输出：

```json
{
  "coupons": [
    {
      "couponId": 3001,
      "name": "满 299 减 20",
      "discountAmount": 20.00
    }
  ]
}
```

## 15. AI Tool Calling 工具定义

以下工具供 Agent 调用，工具底层可以来自本地 Spring Bean，也可以来自 MCP。

| 工具名 | 所属 Agent | 说明 |
| --- | --- | --- |
| searchProducts | Product Advisor Agent | 根据条件检索商品 |
| getProductDetail | Product Advisor Agent, Knowledge QA Agent | 获取商品详情 |
| compareProducts | Product Advisor Agent | 对比多个商品 |
| getInventory | Product Advisor Agent | 查询 SKU 库存 |
| getUserCoupons | Promotion Agent | 查询用户优惠券 |
| calculateBestPrice | Promotion Agent | 计算最优价格 |
| getOrderStatus | Order Agent | 查询订单状态 |
| getLogisticsTrace | Order Agent | 查询物流轨迹 |
| getRefundPolicy | After-Sales Agent | 查询售后政策 |
| createSupportTicket | After-Sales Agent | 创建客服工单 |

## 16. 接口安全规则

1. `/api/admin/**` 仅允许运营、客服、管理员访问。
2. `/api/orders/**` 只能访问当前用户自己的订单。
3. `/api/after-sales/**` 只能访问当前用户自己的售后单。
4. AI 工具调用必须携带当前用户上下文。
5. 创建订单、取消订单、创建售后等操作不得由模型绕过业务校验。
6. 流式接口需要与普通接口使用相同鉴权逻辑。
