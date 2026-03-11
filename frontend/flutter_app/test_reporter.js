#!/usr/bin/env node
/**
 * Flutter Test Reporter
 * Runs flutter tests and generates a beautiful HTML report (similar to Playwright).
 *
 * Usage:
 *   node test_reporter.js
 *
 * Output:
 *   flutter_test_report/index.html  — opens automatically in your browser
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const REPORT_DIR = path.join(__dirname, 'flutter_test_report');
const REPORT_FILE = path.join(REPORT_DIR, 'index.html');

// ── Run flutter test and collect JSON lines ───────────────────────────────────
console.log('\n🧪 Running Flutter tests...\n');

let jsonOutput = '';
let consoleOutput = '';

try {
    jsonOutput = execSync('flutter test test/ --reporter json 2>&1', {
        cwd: __dirname,
        encoding: 'utf8',
        timeout: 120000,
    });
} catch (e) {
    // flutter test exits with code 1 when tests fail — that's OK, we still have output
    jsonOutput = e.stdout || e.output?.join('') || '';
}

// ── Parse JSON events ─────────────────────────────────────────────────────────
const lines = jsonOutput.split('\n').filter(l => l.trim().startsWith('{'));

const tests = {};
let suiteNames = {};
let totalTime = 0;

for (const line of lines) {
    try {
        const event = JSON.parse(line);

        if (event.type === 'suite') {
            suiteNames[event.suite.id] = path.basename(event.suite.path || 'unknown');
        }

        if (event.type === 'testStart') {
            tests[event.test.id] = {
                name: event.test.name,
                suite: suiteNames[event.test.suiteID] || 'unknown',
                suiteID: event.test.suiteID,
                startTime: event.time,
                status: 'running',
                error: null,
                duration: 0,
            };
        }

        if (event.type === 'testDone') {
            if (tests[event.testID]) {
                tests[event.testID].status = event.result; // passed / failed / error
                tests[event.testID].duration = event.time - (tests[event.testID].startTime || 0);
                tests[event.testID].hidden = event.hidden;
                totalTime = Math.max(totalTime, event.time);
            }
        }

        if (event.type === 'error') {
            if (tests[event.testID]) {
                tests[event.testID].error = (event.error || '') + '\n' + (event.stackTrace || '');
            }
        }
    } catch (_) { }
}

// ── Compute stats ─────────────────────────────────────────────────────────────
const allTests = Object.values(tests).filter(t => !t.hidden);
const passed = allTests.filter(t => t.status === 'success').length;
const failed = allTests.filter(t => t.status === 'failure' || t.status === 'error').length;
const total = allTests.length;

// Group by suite
const suites = {};
for (const t of allTests) {
    if (!suites[t.suite]) suites[t.suite] = [];
    suites[t.suite].push(t);
}

const totalSec = (totalTime / 1000).toFixed(1);

// ── Build HTML ────────────────────────────────────────────────────────────────
function statusIcon(s) {
    if (s === 'success') return '✅';
    if (s === 'failure' || s === 'error') return '❌';
    return '⏭️';
}
function statusClass(s) {
    if (s === 'success') return 'passed';
    if (s === 'failure' || s === 'error') return 'failed';
    return 'skipped';
}

let suitesHTML = '';
for (const [suiteName, tests] of Object.entries(suites)) {
    const suitePass = tests.filter(t => t.status === 'success').length;
    const suiteFail = tests.filter(t => t.status !== 'success').length;
    const suiteStatus = suiteFail > 0 ? 'failed' : 'passed';

    const testsHTML = tests.map(t => `
    <div class="test-row ${statusClass(t.status)}">
      <span class="test-icon">${statusIcon(t.status)}</span>
      <span class="test-name">${escapeHtml(t.name)}</span>
      <span class="test-duration">${(t.duration / 1000).toFixed(2)}s</span>
      ${t.error ? `<pre class="test-error">${escapeHtml(t.error)}</pre>` : ''}
    </div>
  `).join('');

    suitesHTML += `
    <div class="suite ${suiteStatus}">
      <div class="suite-header" onclick="this.parentElement.classList.toggle('collapsed')">
        <span class="suite-icon">${suiteFail > 0 ? '❌' : '✅'}</span>
        <span class="suite-name">${escapeHtml(suiteName)}</span>
        <span class="suite-stats">${suitePass} passed, ${suiteFail} failed</span>
        <span class="chevron">▼</span>
      </div>
      <div class="suite-tests">${testsHTML}</div>
    </div>
  `;
}

function escapeHtml(str) {
    return String(str || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

const now = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
const overallClass = failed > 0 ? 'overall-failed' : 'overall-passed';
const overallLabel = failed > 0 ? `${failed} Failed` : 'All Passed';

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Flutter Test Report</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Segoe UI', system-ui, sans-serif; background: #0f1117; color: #e2e8f0; min-height: 100vh; }

  header { background: linear-gradient(135deg, #1a1f2e 0%, #0d1117 100%); border-bottom: 1px solid #2d3748; padding: 32px 40px; }
  .header-top { display: flex; align-items: center; gap: 16px; margin-bottom: 8px; }
  .flutter-logo { font-size: 2rem; }
  h1 { font-size: 1.8rem; font-weight: 700; color: #fff; }
  .header-sub { color: #718096; font-size: 0.9rem; }

  .summary { display: flex; gap: 20px; padding: 24px 40px; flex-wrap: wrap; }
  .stat-card { background: #1a1f2e; border: 1px solid #2d3748; border-radius: 12px; padding: 20px 28px; flex: 1; min-width: 160px; }
  .stat-number { font-size: 2.4rem; font-weight: 800; line-height: 1; }
  .stat-label { font-size: 0.85rem; color: #718096; margin-top: 4px; text-transform: uppercase; letter-spacing: 0.5px; }
  .stat-passed .stat-number { color: #48bb78; }
  .stat-failed .stat-number { color: #fc8181; }
  .stat-total .stat-number { color: #63b3ed; }
  .stat-time .stat-number { color: #b794f4; font-size: 1.8rem; }

  .overall-badge { display: inline-block; padding: 6px 18px; border-radius: 999px; font-weight: 700; font-size: 0.9rem; margin-top: 8px; }
  .overall-passed { background: #22543d; color: #9ae6b4; }
  .overall-failed { background: #742a2a; color: #feb2b2; }

  .content { padding: 24px 40px; }
  h2 { font-size: 1.1rem; font-weight: 600; color: #a0aec0; margin-bottom: 16px; text-transform: uppercase; letter-spacing: 1px; }

  .suite { background: #1a1f2e; border: 1px solid #2d3748; border-radius: 12px; margin-bottom: 12px; overflow: hidden; }
  .suite.failed { border-left: 4px solid #fc8181; }
  .suite.passed { border-left: 4px solid #48bb78; }
  .suite-header { display: flex; align-items: center; gap: 12px; padding: 16px 20px; cursor: pointer; user-select: none; transition: background 0.15s; }
  .suite-header:hover { background: #2d3748; }
  .suite-icon { font-size: 1.1rem; }
  .suite-name { font-weight: 600; flex: 1; font-size: 0.95rem; }
  .suite-stats { font-size: 0.8rem; color: #718096; background: #2d3748; padding: 3px 10px; border-radius: 999px; }
  .chevron { color: #718096; font-size: 0.75rem; transition: transform 0.2s; }
  .suite.collapsed .chevron { transform: rotate(-90deg); }
  .suite.collapsed .suite-tests { display: none; }

  .suite-tests { border-top: 1px solid #2d3748; padding: 4px 0; }
  .test-row { display: flex; align-items: flex-start; gap: 12px; padding: 10px 20px 10px 40px; border-bottom: 1px solid #1a1f2e; flex-wrap: wrap; }
  .test-row:last-child { border-bottom: none; }
  .test-row.passed { }
  .test-row.failed { background: rgba(252, 129, 129, 0.04); }
  .test-icon { font-size: 0.9rem; margin-top: 1px; }
  .test-name { flex: 1; font-size: 0.88rem; color: #cbd5e0; }
  .test-duration { font-size: 0.78rem; color: #4a5568; background: #2d3748; padding: 2px 8px; border-radius: 999px; white-space: nowrap; }
  .test-error { width: 100%; margin-top: 8px; padding: 12px; background: #1a0a0a; border: 1px solid #742a2a; border-radius: 8px; font-size: 0.78rem; color: #feb2b2; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }

  footer { text-align: center; padding: 32px; color: #4a5568; font-size: 0.82rem; border-top: 1px solid #2d3748; margin-top: 16px; }
</style>
</head>
<body>

<header>
  <div class="header-top">
    <span class="flutter-logo">🐦</span>
    <h1>Flutter Test Report</h1>
  </div>
  <div class="header-sub">AI Crop Disease Diagnosis System · ${now}</div>
  <div style="margin-top:12px">
    <span class="overall-badge ${overallClass}">${overallLabel}</span>
  </div>
</header>

<div class="summary">
  <div class="stat-card stat-total">
    <div class="stat-number">${total}</div>
    <div class="stat-label">Total Tests</div>
  </div>
  <div class="stat-card stat-passed">
    <div class="stat-number">${passed}</div>
    <div class="stat-label">Passed</div>
  </div>
  <div class="stat-card stat-failed">
    <div class="stat-number">${failed}</div>
    <div class="stat-label">Failed</div>
  </div>
  <div class="stat-card stat-time">
    <div class="stat-number">${totalSec}s</div>
    <div class="stat-label">Duration</div>
  </div>
</div>

<div class="content">
  <h2>Test Suites</h2>
  ${suitesHTML || '<p style="color:#718096">No tests found.</p>'}
</div>

<footer>
  Generated by Flutter Test Reporter · ${now}
</footer>

<script>
  // Auto-expand failed suites
  document.querySelectorAll('.suite.failed').forEach(s => s.classList.remove('collapsed'));
  // Auto-collapse passed suites for cleanliness
  document.querySelectorAll('.suite.passed').forEach(s => s.classList.add('collapsed'));
</script>
</body>
</html>`;

// ── Write report ──────────────────────────────────────────────────────────────
if (!fs.existsSync(REPORT_DIR)) fs.mkdirSync(REPORT_DIR, { recursive: true });
fs.writeFileSync(REPORT_FILE, html, 'utf8');

// ── Print summary to terminal (like Playwright) ───────────────────────────────
console.log(`Running ${total} tests\n`);
for (const [suiteName, tests] of Object.entries(suites)) {
    for (const t of tests) {
        const icon = t.status === 'success' ? '✓' : '✗';
        const dur = (t.duration / 1000).toFixed(2) + 's';
        console.log(`  ${icon} ${suiteName} › ${t.name}  (${dur})`);
        if (t.error) console.log(`    Error: ${t.error.split('\n')[0]}`);
    }
}

console.log(`\n${'─'.repeat(60)}`);
if (failed > 0) {
    console.log(`  ${failed} failed, ${passed} passed (${totalSec}s)`);
} else {
    console.log(`  ${passed} passed (${totalSec}s)`);
}
console.log(`${'─'.repeat(60)}`);
console.log(`\n📄 HTML Report: ${REPORT_FILE}`);

// ── Open report in browser ────────────────────────────────────────────────────
try {
    const open = process.platform === 'win32' ? 'start' : process.platform === 'darwin' ? 'open' : 'xdg-open';
    execSync(`${open} "${REPORT_FILE}"`);
    console.log('🌐 Opening report in browser...\n');
} catch (_) {
    console.log('Open the report manually in your browser.\n');
}

process.exit(failed > 0 ? 1 : 0);
