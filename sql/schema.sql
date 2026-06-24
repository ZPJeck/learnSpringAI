-- SmartMall AI Assistant database schema
-- Target database: PostgreSQL 15+ with pgvector extension

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS sm_user (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(128) NOT NULL,
    phone VARCHAR(32),
    email VARCHAR(128),
    role VARCHAR(32) NOT NULL DEFAULT 'CUSTOMER',
    status VARCHAR(32) NOT NULL DEFAULT 'ENABLED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sm_category (
    id BIGSERIAL PRIMARY KEY,
    parent_id BIGINT,
    name VARCHAR(128) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'ENABLED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_category_parent_id ON sm_category(parent_id);

CREATE TABLE IF NOT EXISTS sm_product (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL REFERENCES sm_category(id),
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(128),
    subtitle VARCHAR(255),
    description TEXT,
    main_image_url VARCHAR(1024),
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
    min_price NUMERIC(12, 2) NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    sales_count BIGINT NOT NULL DEFAULT 0,
    created_by BIGINT REFERENCES sm_user(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_product_category_id ON sm_product(category_id);
CREATE INDEX IF NOT EXISTS idx_sm_product_status ON sm_product(status);
CREATE INDEX IF NOT EXISTS idx_sm_product_brand ON sm_product(brand);
CREATE INDEX IF NOT EXISTS idx_sm_product_tags_gin ON sm_product USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_sm_product_attributes_gin ON sm_product USING GIN(attributes);

CREATE TABLE IF NOT EXISTS sm_sku (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES sm_product(id),
    sku_code VARCHAR(128) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    specs JSONB NOT NULL DEFAULT '{}'::jsonb,
    price NUMERIC(12, 2) NOT NULL,
    original_price NUMERIC(12, 2),
    image_url VARCHAR(1024),
    status VARCHAR(32) NOT NULL DEFAULT 'ENABLED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_sku_product_id ON sm_sku(product_id);
CREATE INDEX IF NOT EXISTS idx_sm_sku_status ON sm_sku(status);

CREATE TABLE IF NOT EXISTS sm_inventory (
    id BIGSERIAL PRIMARY KEY,
    sku_id BIGINT NOT NULL UNIQUE REFERENCES sm_sku(id),
    available_stock INT NOT NULL DEFAULT 0,
    locked_stock INT NOT NULL DEFAULT 0,
    low_stock_threshold INT NOT NULL DEFAULT 10,
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sm_inventory_stock_non_negative CHECK (available_stock >= 0 AND locked_stock >= 0)
);

CREATE TABLE IF NOT EXISTS sm_coupon (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    coupon_type VARCHAR(32) NOT NULL,
    threshold_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount_rate NUMERIC(5, 4),
    applicable_scope VARCHAR(32) NOT NULL DEFAULT 'ALL',
    applicable_product_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    applicable_category_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_quantity INT NOT NULL DEFAULT 0,
    received_quantity INT NOT NULL DEFAULT 0,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ENABLED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_coupon_status_time ON sm_coupon(status, start_at, end_at);

CREATE TABLE IF NOT EXISTS sm_user_coupon (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    coupon_id BIGINT NOT NULL REFERENCES sm_coupon(id),
    status VARCHAR(32) NOT NULL DEFAULT 'UNUSED',
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    used_at TIMESTAMPTZ,
    order_no VARCHAR(64),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_user_coupon_user_status ON sm_user_coupon(user_id, status);
CREATE INDEX IF NOT EXISTS idx_sm_user_coupon_coupon_id ON sm_user_coupon(coupon_id);

CREATE TABLE IF NOT EXISTS sm_order (
    id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    order_status VARCHAR(32) NOT NULL DEFAULT 'PENDING_PAYMENT',
    pay_status VARCHAR(32) NOT NULL DEFAULT 'UNPAID',
    logistics_status VARCHAR(32) NOT NULL DEFAULT 'NOT_SHIPPED',
    logistics_no VARCHAR(128),
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    pay_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    coupon_id BIGINT,
    receiver_name VARCHAR(128) NOT NULL,
    receiver_phone VARCHAR(32) NOT NULL,
    receiver_address VARCHAR(512) NOT NULL,
    remark VARCHAR(512),
    paid_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_order_user_id ON sm_order(user_id);
CREATE INDEX IF NOT EXISTS idx_sm_order_status ON sm_order(order_status);
CREATE INDEX IF NOT EXISTS idx_sm_order_created_at ON sm_order(created_at);

CREATE TABLE IF NOT EXISTS sm_order_item (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sm_order(id),
    order_no VARCHAR(64) NOT NULL,
    product_id BIGINT NOT NULL REFERENCES sm_product(id),
    sku_id BIGINT NOT NULL REFERENCES sm_sku(id),
    product_name VARCHAR(255) NOT NULL,
    sku_name VARCHAR(255) NOT NULL,
    product_image_url VARCHAR(1024),
    unit_price NUMERIC(12, 2) NOT NULL,
    quantity INT NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sm_order_item_quantity_positive CHECK (quantity > 0)
);

CREATE INDEX IF NOT EXISTS idx_sm_order_item_order_id ON sm_order_item(order_id);
CREATE INDEX IF NOT EXISTS idx_sm_order_item_order_no ON sm_order_item(order_no);
CREATE INDEX IF NOT EXISTS idx_sm_order_item_product_id ON sm_order_item(product_id);

CREATE TABLE IF NOT EXISTS sm_review (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    product_id BIGINT NOT NULL REFERENCES sm_product(id),
    sku_id BIGINT REFERENCES sm_sku(id),
    order_no VARCHAR(64),
    rating INT NOT NULL,
    content TEXT NOT NULL,
    images JSONB NOT NULL DEFAULT '[]'::jsonb,
    status VARCHAR(32) NOT NULL DEFAULT 'PUBLISHED',
    ai_summary_tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_sm_review_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_sm_review_product_id ON sm_review(product_id);
CREATE INDEX IF NOT EXISTS idx_sm_review_user_id ON sm_review(user_id);

CREATE TABLE IF NOT EXISTS sm_after_sales (
    id BIGSERIAL PRIMARY KEY,
    after_sales_no VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    order_id BIGINT NOT NULL REFERENCES sm_order(id),
    order_no VARCHAR(64) NOT NULL,
    order_item_id BIGINT REFERENCES sm_order_item(id),
    after_sales_type VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING_REVIEW',
    reason VARCHAR(255) NOT NULL,
    description TEXT,
    refund_amount NUMERIC(12, 2),
    reviewer_id BIGINT REFERENCES sm_user(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_after_sales_user_id ON sm_after_sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sm_after_sales_order_no ON sm_after_sales(order_no);
CREATE INDEX IF NOT EXISTS idx_sm_after_sales_status ON sm_after_sales(status);

CREATE TABLE IF NOT EXISTS sm_ai_conversation (
    id BIGSERIAL PRIMARY KEY,
    conversation_id VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    title VARCHAR(255),
    scene VARCHAR(64) NOT NULL DEFAULT 'SHOPPING',
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    last_message_preview VARCHAR(512),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_ai_conversation_user_id ON sm_ai_conversation(user_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_conversation_updated_at ON sm_ai_conversation(updated_at);

CREATE TABLE IF NOT EXISTS sm_ai_message (
    id BIGSERIAL PRIMARY KEY,
    message_id VARCHAR(64) NOT NULL UNIQUE,
    conversation_id VARCHAR(64) NOT NULL REFERENCES sm_ai_conversation(conversation_id),
    user_id BIGINT NOT NULL REFERENCES sm_user(id),
    role VARCHAR(32) NOT NULL,
    agent_code VARCHAR(64),
    content TEXT NOT NULL,
    structured_result JSONB NOT NULL DEFAULT '{}'::jsonb,
    feedback_rating VARCHAR(32),
    feedback_reason VARCHAR(512),
    token_count INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_ai_message_conversation_id ON sm_ai_message(conversation_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_message_user_id ON sm_ai_message(user_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_message_created_at ON sm_ai_message(created_at);

CREATE TABLE IF NOT EXISTS sm_ai_agent_trace (
    id BIGSERIAL PRIMARY KEY,
    trace_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64),
    message_id VARCHAR(64),
    user_id BIGINT REFERENCES sm_user(id),
    agent_code VARCHAR(64) NOT NULL,
    intent VARCHAR(64),
    confidence NUMERIC(5, 4),
    input_summary TEXT,
    output_summary TEXT,
    status VARCHAR(32) NOT NULL,
    error_message TEXT,
    duration_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_ai_agent_trace_trace_id ON sm_ai_agent_trace(trace_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_agent_trace_conversation_id ON sm_ai_agent_trace(conversation_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_agent_trace_agent_code ON sm_ai_agent_trace(agent_code);
CREATE INDEX IF NOT EXISTS idx_sm_ai_agent_trace_created_at ON sm_ai_agent_trace(created_at);

CREATE TABLE IF NOT EXISTS sm_ai_tool_invocation (
    id BIGSERIAL PRIMARY KEY,
    trace_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64),
    message_id VARCHAR(64),
    user_id BIGINT REFERENCES sm_user(id),
    agent_code VARCHAR(64),
    tool_name VARCHAR(128) NOT NULL,
    tool_source VARCHAR(32) NOT NULL DEFAULT 'LOCAL',
    request_args JSONB NOT NULL DEFAULT '{}'::jsonb,
    response_summary TEXT,
    status VARCHAR(32) NOT NULL,
    error_message TEXT,
    duration_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_ai_tool_invocation_trace_id ON sm_ai_tool_invocation(trace_id);
CREATE INDEX IF NOT EXISTS idx_sm_ai_tool_invocation_tool_name ON sm_ai_tool_invocation(tool_name);
CREATE INDEX IF NOT EXISTS idx_sm_ai_tool_invocation_status ON sm_ai_tool_invocation(status);
CREATE INDEX IF NOT EXISTS idx_sm_ai_tool_invocation_created_at ON sm_ai_tool_invocation(created_at);

CREATE TABLE IF NOT EXISTS sm_model_call_log (
    id BIGSERIAL PRIMARY KEY,
    trace_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64),
    message_id VARCHAR(64),
    user_id BIGINT REFERENCES sm_user(id),
    provider VARCHAR(64),
    model_name VARCHAR(128) NOT NULL,
    call_type VARCHAR(32) NOT NULL,
    prompt_tokens INT,
    completion_tokens INT,
    total_tokens INT,
    request_summary TEXT,
    response_summary TEXT,
    status VARCHAR(32) NOT NULL,
    error_message TEXT,
    duration_ms INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_model_call_log_trace_id ON sm_model_call_log(trace_id);
CREATE INDEX IF NOT EXISTS idx_sm_model_call_log_model_name ON sm_model_call_log(model_name);
CREATE INDEX IF NOT EXISTS idx_sm_model_call_log_created_at ON sm_model_call_log(created_at);

CREATE TABLE IF NOT EXISTS sm_knowledge_document (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    doc_type VARCHAR(64) NOT NULL,
    source_type VARCHAR(64) NOT NULL DEFAULT 'UPLOAD',
    source_uri VARCHAR(1024),
    file_name VARCHAR(255),
    file_mime_type VARCHAR(128),
    product_id BIGINT REFERENCES sm_product(id),
    category_id BIGINT REFERENCES sm_category(id),
    version VARCHAR(64) NOT NULL DEFAULT 'v1',
    status VARCHAR(32) NOT NULL DEFAULT 'UPLOADED',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    uploaded_by BIGINT REFERENCES sm_user(id),
    indexed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_knowledge_document_doc_type ON sm_knowledge_document(doc_type);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_document_product_id ON sm_knowledge_document(product_id);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_document_category_id ON sm_knowledge_document(category_id);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_document_status ON sm_knowledge_document(status);

CREATE TABLE IF NOT EXISTS sm_knowledge_chunk (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT NOT NULL REFERENCES sm_knowledge_document(id) ON DELETE CASCADE,
    chunk_no INT NOT NULL,
    title VARCHAR(255),
    content TEXT NOT NULL,
    content_hash VARCHAR(128),
    token_count INT,
    embedding vector(1536),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    product_id BIGINT,
    category_id BIGINT,
    doc_type VARCHAR(64),
    version VARCHAR(64) NOT NULL DEFAULT 'v1',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_document_id ON sm_knowledge_chunk(document_id);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_product_id ON sm_knowledge_chunk(product_id);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_category_id ON sm_knowledge_chunk(category_id);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_doc_type ON sm_knowledge_chunk(doc_type);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_enabled ON sm_knowledge_chunk(enabled);
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_metadata_gin ON sm_knowledge_chunk USING GIN(metadata);

-- Choose vector_l2_ops, vector_ip_ops, or vector_cosine_ops according to embedding model and query strategy.
CREATE INDEX IF NOT EXISTS idx_sm_knowledge_chunk_embedding_hnsw
    ON sm_knowledge_chunk
    USING hnsw (embedding vector_cosine_ops);

CREATE TABLE IF NOT EXISTS sm_rag_hit_log (
    id BIGSERIAL PRIMARY KEY,
    trace_id VARCHAR(64) NOT NULL,
    conversation_id VARCHAR(64),
    message_id VARCHAR(64),
    user_id BIGINT REFERENCES sm_user(id),
    query TEXT NOT NULL,
    document_id BIGINT REFERENCES sm_knowledge_document(id),
    chunk_id BIGINT REFERENCES sm_knowledge_chunk(id),
    score NUMERIC(8, 6),
    rank_no INT,
    content_preview TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sm_rag_hit_log_trace_id ON sm_rag_hit_log(trace_id);
CREATE INDEX IF NOT EXISTS idx_sm_rag_hit_log_conversation_id ON sm_rag_hit_log(conversation_id);
CREATE INDEX IF NOT EXISTS idx_sm_rag_hit_log_document_id ON sm_rag_hit_log(document_id);
CREATE INDEX IF NOT EXISTS idx_sm_rag_hit_log_created_at ON sm_rag_hit_log(created_at);

CREATE TABLE IF NOT EXISTS sm_ai_agent_config (
    id BIGSERIAL PRIMARY KEY,
    agent_code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    system_prompt TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    tool_names JSONB NOT NULL DEFAULT '[]'::jsonb,
    rag_filters JSONB NOT NULL DEFAULT '{}'::jsonb,
    output_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sm_mcp_server_registry (
    id BIGSERIAL PRIMARY KEY,
    server_code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    transport VARCHAR(32) NOT NULL,
    endpoint VARCHAR(1024) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    last_heartbeat_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sm_mcp_tool_registry (
    id BIGSERIAL PRIMARY KEY,
    server_code VARCHAR(64) NOT NULL REFERENCES sm_mcp_server_registry(server_code),
    tool_name VARCHAR(128) NOT NULL,
    description TEXT,
    input_schema JSONB NOT NULL DEFAULT '{}'::jsonb,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(server_code, tool_name)
);

CREATE INDEX IF NOT EXISTS idx_sm_mcp_tool_registry_server_code ON sm_mcp_tool_registry(server_code);
CREATE INDEX IF NOT EXISTS idx_sm_mcp_tool_registry_tool_name ON sm_mcp_tool_registry(tool_name);

INSERT INTO sm_ai_agent_config (agent_code, name, description, system_prompt, tool_names, rag_filters, output_schema)
VALUES
    ('ROUTER', 'Router Agent', '识别用户意图并路由到对应业务 Agent。', '你是智能商城的意图路由 Agent，只输出结构化路由结果。', '[]'::jsonb, '{}'::jsonb, '{}'::jsonb),
    ('PRODUCT_ADVISOR', 'Product Advisor Agent', '负责商品推荐和商品对比。', '你是智能商城导购助手，必须基于商品工具和知识库给出推荐。', '["searchProducts","getProductDetail","getInventory","calculateBestPrice"]'::jsonb, '{"docType":["PRODUCT_MANUAL","PRODUCT_DETAIL","REVIEW_SUMMARY"]}'::jsonb, '{}'::jsonb),
    ('KNOWLEDGE_QA', 'Knowledge QA Agent', '负责商品知识、FAQ 和平台规则问答。', '你是智能商城知识库问答助手，必须基于检索到的知识回答。', '["getProductDetail"]'::jsonb, '{"docType":["PRODUCT_MANUAL","FAQ","AFTER_SALES_POLICY","PROMOTION_RULE"]}'::jsonb, '{}'::jsonb),
    ('ORDER', 'Order Agent', '负责订单和物流查询。', '你是智能商城订单助手，订单状态必须来自订单工具或 MCP 工具。', '["getOrderStatus","getLogisticsTrace"]'::jsonb, '{"docType":["FAQ"]}'::jsonb, '{}'::jsonb),
    ('AFTER_SALES', 'After-Sales Agent', '负责退换货、维修和退款咨询。', '你是智能商城售后助手，售后政策必须基于知识库和订单工具判断。', '["getOrderStatus","getRefundPolicy","createSupportTicket"]'::jsonb, '{"docType":["AFTER_SALES_POLICY","FAQ"]}'::jsonb, '{}'::jsonb),
    ('PROMOTION', 'Promotion Agent', '负责优惠券和活动咨询。', '你是智能商城优惠活动助手，优惠价格必须来自优惠工具。', '["getUserCoupons","calculateBestPrice"]'::jsonb, '{"docType":["PROMOTION_RULE","FAQ"]}'::jsonb, '{}'::jsonb),
    ('OPERATION', 'Operation Agent', '负责商品卖点、FAQ 和评论摘要等运营内容生成。', '你是智能商城运营助手，生成内容要基于商品资料和评论数据。', '["getProductDetail","summarizeReviews"]'::jsonb, '{"docType":["PRODUCT_MANUAL","PRODUCT_DETAIL","REVIEW_SUMMARY"]}'::jsonb, '{}'::jsonb)
ON CONFLICT (agent_code) DO NOTHING;

INSERT INTO sm_mcp_server_registry (server_code, name, transport, endpoint, status, enabled)
VALUES
    ('order-mcp', '订单 MCP 服务', 'HTTP', 'http://localhost:8091/mcp', 'UNKNOWN', TRUE),
    ('logistics-mcp', '物流 MCP 服务', 'HTTP', 'http://localhost:8092/mcp', 'UNKNOWN', TRUE),
    ('promotion-mcp', '优惠 MCP 服务', 'HTTP', 'http://localhost:8093/mcp', 'UNKNOWN', TRUE)
ON CONFLICT (server_code) DO NOTHING;

INSERT INTO sm_mcp_tool_registry (server_code, tool_name, description, input_schema, enabled)
VALUES
    ('order-mcp', 'order.getStatus', '查询订单状态。', '{}'::jsonb, TRUE),
    ('order-mcp', 'order.getAfterSalesStatus', '查询售后单状态。', '{}'::jsonb, TRUE),
    ('logistics-mcp', 'logistics.getTrace', '查询物流轨迹。', '{}'::jsonb, TRUE),
    ('logistics-mcp', 'logistics.estimateDelivery', '查询预计送达时间。', '{}'::jsonb, TRUE),
    ('promotion-mcp', 'promotion.calculateBestPrice', '计算最优优惠价格。', '{}'::jsonb, TRUE),
    ('promotion-mcp', 'promotion.getAvailableCoupons', '查询可用优惠券。', '{}'::jsonb, TRUE)
ON CONFLICT (server_code, tool_name) DO NOTHING;
