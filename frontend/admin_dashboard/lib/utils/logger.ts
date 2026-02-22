/**
 * logger.ts — Structured logger for the Next.js admin dashboard.
 *
 * Uses console.* with structured format — no external packages needed.
 * Logs appear in:
 *   - `npm run dev` terminal output (server-side)
 *   - Browser DevTools console (client-side)
 *
 * Usage:
 *   import { logger } from '@/lib/utils/logger';
 *   logger.info('Users loaded', { count: 42 });
 *   logger.error('API failed', { endpoint: '/market', error: e.message });
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogEntry {
    timestamp: string;
    level: LogLevel;
    message: string;
    context?: Record<string, unknown>;
}

function formatEntry(entry: LogEntry): string {
    const ctx = entry.context ? ` ${JSON.stringify(entry.context)}` : '';
    return `[${entry.timestamp}] [${entry.level.toUpperCase().padEnd(5)}] ${entry.message}${ctx}`;
}

function createEntry(
    level: LogLevel,
    message: string,
    context?: Record<string, unknown>
): LogEntry {
    return {
        timestamp: new Date().toISOString(),
        level,
        message,
        context,
    };
}

export const logger = {
    debug(message: string, context?: Record<string, unknown>) {
        if (process.env.NODE_ENV === 'development') {
            const entry = createEntry('debug', message, context);
            console.debug(formatEntry(entry));
        }
    },

    info(message: string, context?: Record<string, unknown>) {
        const entry = createEntry('info', message, context);
        console.info(formatEntry(entry));
    },

    warn(message: string, context?: Record<string, unknown>) {
        const entry = createEntry('warn', message, context);
        console.warn(formatEntry(entry));
    },

    error(message: string, context?: Record<string, unknown>) {
        const entry = createEntry('error', message, context);
        console.error(formatEntry(entry));
    },
};

export default logger;
