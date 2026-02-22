'use client';

import { useEffect, useState, useCallback } from 'react';
import { AlertCircle, MessageSquare, X, RefreshCw, Clock, CheckCircle, XCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';

interface Answer {
    id: string;
    expert_name: string;
    answer_text: string;
    rating: number | null;
    created_at: string;
}

interface Question {
    id: string;
    question_text: string;
    status: string;
    media_path: string | null;
    created_at: string;
    farmer: {
        id: string | null;
        name: string;
        email: string | null;
    };
    answers: Answer[];
    answer_count: number;
}

const statusColors: Record<string, { bg: string; text: string; icon: React.ElementType }> = {
    OPEN: { bg: 'bg-amber-50 border-amber-200', text: 'text-amber-700', icon: Clock },
    ANSWERED: { bg: 'bg-green-50 border-green-200', text: 'text-green-700', icon: CheckCircle },
    CLOSED: { bg: 'bg-slate-100 border-slate-200', text: 'text-slate-500', icon: XCircle },
};

export default function QuestionsPage() {
    const [questions, setQuestions] = useState<Question[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [page, setPage] = useState(1);
    const [total, setTotal] = useState(0);
    const [statusFilter, setStatusFilter] = useState<string>('');
    const [closingId, setClosingId] = useState<string | null>(null);
    const [expandedId, setExpandedId] = useState<string | null>(null);

    const loadQuestions = useCallback(async () => {
        setLoading(true);
        try {
            const res = await adminApi.getQuestions(page, statusFilter || undefined);
            setQuestions(res.data.questions || []);
            setTotal(res.data.total || 0);
            setError('');
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load questions');
        } finally {
            setLoading(false);
        }
    }, [page, statusFilter]);

    useEffect(() => { loadQuestions(); }, [loadQuestions]);

    const handleClose = async (id: string) => {
        if (!confirm('Close this question? This cannot be undone.')) return;
        setClosingId(id);
        try {
            await adminApi.closeQuestion(id);
            await loadQuestions();
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to close question');
        } finally {
            setClosingId(null);
        }
    };

    const pageSize = 20;
    const totalPages = Math.ceil(total / pageSize);

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900">Questions</h1>
                    <p className="text-slate-500 text-sm mt-0.5">
                        Farmer questions &amp; expert answers ({total} total)
                    </p>
                </div>
                <button
                    onClick={loadQuestions}
                    className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm hover:bg-slate-50 transition"
                >
                    <RefreshCw size={16} />
                    Refresh
                </button>
            </div>

            {/* Filters */}
            <div className="flex gap-2">
                {['', 'OPEN', 'ANSWERED', 'CLOSED'].map((s) => (
                    <button
                        key={s}
                        onClick={() => { setStatusFilter(s); setPage(1); }}
                        className={`px-4 py-1.5 rounded-full text-sm font-medium transition ${statusFilter === s
                            ? 'bg-indigo-600 text-white'
                            : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
                            }`}
                    >
                        {s || 'All'}
                    </button>
                ))}
            </div>

            {/* Error */}
            {error && (
                <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 flex items-center gap-3">
                    <AlertCircle size={20} />
                    <p>{error}</p>
                </div>
            )}

            {/* Questions List */}
            {loading ? (
                <div className="flex justify-center py-20">
                    <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                </div>
            ) : questions.length === 0 ? (
                <div className="text-center py-20 text-slate-400">
                    <MessageSquare size={48} className="mx-auto mb-4 opacity-30" />
                    <p>No questions found</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {questions.map((q) => {
                        const style = statusColors[q.status] || statusColors.OPEN;
                        const StatusIcon = style.icon;
                        const isExpanded = expandedId === q.id;

                        return (
                            <div key={q.id} className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                                {/* Question Header */}
                                <div
                                    className="p-5 cursor-pointer hover:bg-slate-50 transition"
                                    onClick={() => setExpandedId(isExpanded ? null : q.id)}
                                >
                                    <div className="flex items-start justify-between gap-4">
                                        <div className="flex-1 min-w-0">
                                            <p className="text-sm text-slate-900 font-medium line-clamp-2">
                                                {q.question_text}
                                            </p>
                                            <div className="flex items-center gap-3 mt-2 text-xs text-slate-400">
                                                <span>by <span className="text-slate-600">{q.farmer.name}</span></span>
                                                <span>•</span>
                                                <span>{new Date(q.created_at).toLocaleDateString()}</span>
                                                <span>•</span>
                                                <span>{q.answer_count} answer(s)</span>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2 shrink-0">
                                            <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${style.bg} ${style.text}`}>
                                                <StatusIcon size={12} />
                                                {q.status}
                                            </span>
                                            {q.status !== 'CLOSED' && (
                                                <button
                                                    onClick={(e) => { e.stopPropagation(); handleClose(q.id); }}
                                                    disabled={closingId === q.id}
                                                    className="p-1.5 rounded-lg text-slate-400 hover:bg-red-50 hover:text-red-500 transition disabled:opacity-50"
                                                    title="Close question"
                                                >
                                                    {closingId === q.id ? (
                                                        <div className="w-4 h-4 border-2 border-red-200 border-t-red-500 rounded-full animate-spin" />
                                                    ) : (
                                                        <X size={16} />
                                                    )}
                                                </button>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                {/* Expanded Answers */}
                                {isExpanded && q.answers.length > 0 && (
                                    <div className="border-t border-slate-100 bg-slate-50 p-5 space-y-3">
                                        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Expert Answers</p>
                                        {q.answers.map((a) => (
                                            <div key={a.id} className="bg-white rounded-lg p-4 border border-slate-200">
                                                <div className="flex items-center justify-between mb-2">
                                                    <span className="text-xs font-semibold text-indigo-600">{a.expert_name}</span>
                                                    <span className="text-xs text-slate-400">{new Date(a.created_at).toLocaleDateString()}</span>
                                                </div>
                                                <p className="text-sm text-slate-700">{a.answer_text}</p>
                                                {a.rating && (
                                                    <div className="mt-2 flex items-center gap-1">
                                                        {Array.from({ length: 5 }).map((_, i) => (
                                                            <span key={i} className={`text-sm ${i < a.rating! ? 'text-amber-400' : 'text-slate-200'}`}>★</span>
                                                        ))}
                                                        <span className="text-xs text-slate-400 ml-1">{a.rating}/5</span>
                                                    </div>
                                                )}
                                            </div>
                                        ))}
                                    </div>
                                )}

                                {isExpanded && q.answers.length === 0 && (
                                    <div className="border-t border-slate-100 bg-slate-50 p-5 text-center text-sm text-slate-400">
                                        No answers yet
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}

            {/* Pagination */}
            {totalPages > 1 && (
                <div className="flex justify-center gap-2 pt-4">
                    <button
                        onClick={() => setPage((p) => Math.max(1, p - 1))}
                        disabled={page === 1}
                        className="px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm disabled:opacity-50 hover:bg-slate-50"
                    >
                        Previous
                    </button>
                    <span className="px-4 py-2 text-sm text-slate-600">
                        Page {page} of {totalPages}
                    </span>
                    <button
                        onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                        disabled={page === totalPages}
                        className="px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm disabled:opacity-50 hover:bg-slate-50"
                    >
                        Next
                    </button>
                </div>
            )}
        </div>
    );
}
