import { Check, X, Mail, Briefcase, GraduationCap, Clock } from 'lucide-react';

interface PendingExpert {
    id: string;
    full_name: string;
    email: string;
    expertise_domain: string | null;
    qualification: string | null;
    experience_years: number | null;
}

interface ExpertCardProps {
    expert: PendingExpert;
    isLoading: boolean;
    onApprove: (id: string) => void;
    onReject: (id: string) => void;
}

export default function ExpertCard({ expert, isLoading, onApprove, onReject }: ExpertCardProps) {
    return (
        <div className="bg-white rounded-xl border border-slate-200 p-5 hover:border-slate-300 transition-colors">
            <div className="flex items-start gap-5">
                {/* Avatar */}
                <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-xl flex items-center justify-center text-white text-lg font-bold flex-shrink-0">
                    {expert.full_name.split(' ').map(n => n[0]).join('')}
                </div>

                {/* Details */}
                <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between">
                        <div>
                            <h3 className="text-base font-bold text-slate-900">{expert.full_name}</h3>
                            <div className="flex items-center gap-1.5 text-slate-500 text-sm mt-0.5">
                                <Mail size={13} />
                                {expert.email}
                            </div>
                        </div>
                        <span className="px-2.5 py-1 bg-amber-100 text-amber-700 rounded-md text-xs font-medium">
                            Pending
                        </span>
                    </div>

                    <div className="grid grid-cols-3 gap-4 mt-4">
                        <InfoItem icon={Briefcase} label="Expertise" value={expert.expertise_domain || 'N/A'} color="indigo" />
                        <InfoItem icon={GraduationCap} label="Qualification" value={expert.qualification || 'N/A'} color="purple" />
                        <InfoItem icon={Clock} label="Experience" value={`${expert.experience_years || 0} years`} color="emerald" />
                    </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-2 flex-shrink-0">
                    <button
                        onClick={() => onApprove(expert.id)}
                        disabled={isLoading}
                        className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-all disabled:opacity-50"
                    >
                        {isLoading ? (
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        ) : (
                            <Check size={16} />
                        )}
                        Approve
                    </button>
                    <button
                        onClick={() => onReject(expert.id)}
                        disabled={isLoading}
                        className="flex items-center gap-2 px-4 py-2 bg-white border border-red-200 text-red-600 rounded-lg text-sm font-medium hover:bg-red-50 transition-all disabled:opacity-50"
                    >
                        <X size={16} /> Reject
                    </button>
                </div>
            </div>
        </div>
    );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function InfoItem({ icon: Icon, label, value, color }: { icon: any; label: string; value: string; color: string }) {
    const colors: Record<string, string> = {
        indigo: 'bg-indigo-50 text-indigo-600',
        purple: 'bg-purple-50 text-purple-600',
        emerald: 'bg-emerald-50 text-emerald-600',
    };

    return (
        <div className="flex items-center gap-2.5">
            <div className={`p-1.5 rounded-md ${colors[color]}`}>
                <Icon size={14} />
            </div>
            <div className="min-w-0">
                <p className="text-[10px] text-slate-500 uppercase tracking-wide">{label}</p>
                <p className="text-sm font-medium text-slate-900 truncate">{value}</p>
            </div>
        </div>
    );
}
