-- AI Crop Disease Diagnosis System
-- Database Initialization Script

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table with RBAC
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(20) NOT NULL CHECK (role IN ('FARMER', 'EXPERT', 'ADMIN')),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PENDING', 'SUSPENDED')),
    expertise_domain VARCHAR(255),
    qualification TEXT,
    experience_years INTEGER,
    location VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Diagnoses table
CREATE TABLE IF NOT EXISTS diagnoses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media_path VARCHAR(500) NOT NULL,
    media_type VARCHAR(20) NOT NULL DEFAULT 'image',
    crop_type VARCHAR(100),
    location VARCHAR(255),
    disease VARCHAR(255) NOT NULL,
    severity VARCHAR(50) NOT NULL DEFAULT 'moderate',
    confidence FLOAT NOT NULL,
    treatment JSONB NOT NULL DEFAULT '{}',
    prevention TEXT,
    warnings TEXT,
    additional_diseases JSONB,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    media_path VARCHAR(500),
    question_text TEXT NOT NULL,
    diagnosis_id UUID REFERENCES diagnoses(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'RESOLVED', 'CLOSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Answers table
CREATE TABLE IF NOT EXISTS answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    expert_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Market prices table
CREATE TABLE IF NOT EXISTS market_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    commodity VARCHAR(100) NOT NULL,
    price FLOAT NOT NULL,
    unit VARCHAR(50) DEFAULT 'Quintal',
    location VARCHAR(255) NOT NULL,
    trend VARCHAR(20) DEFAULT 'stable' CHECK (trend IN ('up', 'down', 'stable')),
    change_percent FLOAT DEFAULT 0.0,
    min_price FLOAT,
    max_price FLOAT,
    arrival_qty FLOAT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System logs
CREATE TABLE IF NOT EXISTS system_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    source VARCHAR(100),
    user_id UUID,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System metrics
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    metric_type VARCHAR(50) NOT NULL DEFAULT 'gauge',
    tags JSONB,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily stats
CREATE TABLE IF NOT EXISTS daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    total_diagnoses INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    total_answers INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    avg_confidence FLOAT,
    error_count INTEGER DEFAULT 0
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_diagnoses_user_id ON diagnoses(user_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_created_at ON diagnoses(created_at);
CREATE INDEX IF NOT EXISTS idx_questions_farmer_id ON questions(farmer_id);
CREATE INDEX IF NOT EXISTS idx_questions_status ON questions(status);
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_expert_id ON answers(expert_id);
CREATE INDEX IF NOT EXISTS idx_market_prices_commodity ON market_prices(commodity);
CREATE INDEX IF NOT EXISTS idx_market_prices_location ON market_prices(location);
CREATE INDEX IF NOT EXISTS idx_market_prices_recorded_at ON market_prices(recorded_at);
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON system_logs(level);
CREATE INDEX IF NOT EXISTS idx_system_logs_created_at ON system_logs(created_at);

-- Create default admin user (password: admin123)
-- Note: In production, change this password immediately!
INSERT INTO users (email, password_hash, full_name, role, status) 
VALUES (
    'admin@cropdiagnosis.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.iy3GxWRgC1zGZe',
    'System Admin',
    'ADMIN',
    'ACTIVE'
) ON CONFLICT (email) DO NOTHING;

-- Insert sample market prices
INSERT INTO market_prices (commodity, price, unit, location, trend, change_percent, min_price, max_price, recorded_at) VALUES
('Tomato', 2800, 'Quintal', 'Kolar, Bangalore Rural, Karnataka', 'up', 5.2, 2600, 3000, NOW()),
('Potato', 1500, 'Quintal', 'Hassan, Hassan, Karnataka', 'down', -2.1, 1400, 1600, NOW()),
('Onion', 3200, 'Quintal', 'Nashik, Nashik, Maharashtra', 'up', 8.5, 3000, 3500, NOW()),
('Rice', 2100, 'Quintal', 'Mandya, Mandya, Karnataka', 'stable', 0.5, 2000, 2200, NOW()),
('Wheat', 2400, 'Quintal', 'Dharwad, Dharwad, Karnataka', 'up', 3.2, 2300, 2500, NOW()),
('Cotton', 6800, 'Quintal', 'Raichur, Raichur, Karnataka', 'stable', 0.0, 6500, 7000, NOW()),
('Maize', 1800, 'Quintal', 'Davangere, Davangere, Karnataka', 'up', 4.1, 1700, 1900, NOW()),
('Green Chilli', 4500, 'Quintal', 'Guntur, Guntur, Andhra Pradesh', 'up', 12.5, 4000, 5000, NOW()),
('Groundnut', 5200, 'Quintal', 'Bellary, Bellary, Karnataka', 'down', -1.5, 5000, 5400, NOW()),
('Tur Dal', 7500, 'Quintal', 'Gulbarga, Gulbarga, Karnataka', 'stable', 1.0, 7200, 7800, NOW()),
('Cabbage', 1200, 'Quintal', 'Ooty, Nilgiris, Tamil Nadu', 'down', -3.2, 1100, 1300, NOW()),
('Carrot', 1800, 'Quintal', 'Bangalore, Bangalore Urban, Karnataka', 'stable', 0.0, 1700, 1900, NOW()),
('Cauliflower', 1600, 'Quintal', 'Mysore, Mysore, Karnataka', 'up', 6.5, 1500, 1700, NOW()),
('Beans', 3500, 'Quintal', 'Chikmagalur, Chikmagalur, Karnataka', 'up', 9.2, 3200, 3800, NOW()),
('Brinjal', 2200, 'Quintal', 'Hubli, Dharwad, Karnataka', 'stable', -0.5, 2100, 2300, NOW()),
('Bitter Gourd', 2800, 'Quintal', 'Shimoga, Shimoga, Karnataka', 'down', -4.5, 2600, 3000, NOW()),
('Cucumber', 1400, 'Quintal', 'Tumkur, Tumkur, Karnataka', 'up', 2.8, 1300, 1500, NOW()),
('Capsicum', 4200, 'Quintal', 'Bangalore, Bangalore Urban, Karnataka', 'up', 7.3, 3900, 4500, NOW()),
('Coriander', 6500, 'Quintal', 'Kolar, Bangalore Rural, Karnataka', 'stable', 0.8, 6200, 6800, NOW()),
('Ginger', 8500, 'Quintal', 'Coorg, Kodagu, Karnataka', 'up', 11.2, 7800, 9200, NOW())
ON CONFLICT DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Database initialized successfully!';
    RAISE NOTICE 'Default admin: admin@cropdiagnosis.com / admin123';
END $$;
