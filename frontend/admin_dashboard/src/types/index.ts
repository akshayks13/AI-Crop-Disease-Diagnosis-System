export interface User {
    id: string;
    email: string;
    full_name: string;
    phone?: string;
    role: 'FARMER' | 'EXPERT' | 'ADMIN';
    status: 'ACTIVE' | 'PENDING' | 'SUSPENDED';
    expertise_domain?: string;
    qualification?: string;
    experience_years?: number;
    location?: string;
    created_at: string;
}

export interface PendingExpert extends User {
    expertise_domain: string;
    qualification: string;
    experience_years: number;
}

export interface DashboardMetrics {
    total_users: number;
    total_farmers: number;
    total_experts: number;
    pending_experts: number;
    total_diagnoses: number;
    total_questions: number;
    resolved_questions: number;
    diagnoses_today: number;
    questions_today: number;
    storage_used_mb: number;
}

export interface DashboardTrends {
    diagnoses_this_week: number;
    recent_signups: number;
    open_questions: number;
}

export interface DashboardData {
    metrics: DashboardMetrics;
    trends: DashboardTrends;
    system_health: string;
}

export interface DailyMetric {
    date: string;
    diagnoses: number;
    questions: number;
    signups: number;
}

export interface SystemLog {
    id: string;
    level: string;
    message: string;
    source?: string;
    user_id?: string;
    created_at: string;
}
