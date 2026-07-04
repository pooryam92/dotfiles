#!/usr/bin/env node
// Claude Code status line — shared by Windows and Pop!_OS.
//
// Claude Code runs this script after each turn, feeding it a JSON blob on
// stdin (model, workspace, git, cost, context-window usage, …). Whatever we
// print to stdout becomes the one-line status bar under the prompt.
//
// Why Node? It's the one runtime guaranteed on both machines (Claude Code
// itself runs on it), so a single script serves every OS — no shell fork.
//
// Why ANSI *named* colors (\x1b[36m) instead of Tokyo Night hex codes? Same
// reason the shell prompts use named colors: they resolve against the
// terminal's own palette, which WezTerm sets to Tokyo Night. Switch the
// terminal theme and this bar follows automatically — no color values to keep
// in sync. Glyphs/colors mirror the shell prompts so the status line reads as
// an extension of them.

const { execFileSync } = require('node:child_process');
const os = require('node:os');

// --- tiny color helper -----------------------------------------------------
// SGR codes: 31 red, 32 green, 33 yellow, 34 blue, 35 magenta, 36 cyan,
// 90 bright-black/grey. Prefix "1;" for bold.
const paint = (code, s) => `\x1b[${code}m${s}\x1b[0m`;
const cyan = (s) => paint('1;36', s);
const purple = (s) => paint('1;35', s);
const blue = (s) => paint('1;34', s);
const yellow = (s) => paint('33', s);
const green = (s) => paint('32', s);
const red = (s) => paint('31', s);
const grey = (s) => paint('90', s);

// Compact token counts: 1234 -> "1.2k", 84000 -> "84k", 1000000 -> "1M".
function fmtTokens(n) {
  if (n < 1000) return String(n);
  // 999_500+ rounds up to "1000k"; promote to "1M" so the carry reads right.
  if (n < 999500) return (n / 1000).toFixed(n >= 100000 ? 0 : 1).replace(/\.0$/, '') + 'k';
  return (n / 1000000).toFixed(n % 1000000 === 0 ? 0 : 1).replace(/\.0$/, '') + 'M';
}

// --- path display ----------------------------------------------------------
// Show the directory relative to the project root (its basename as the head),
// (truncate-to-repo style). Outside the project, collapse $HOME
// to ~ and keep the last few segments.
const norm = (p) => (p || '').replace(/\\/g, '/').replace(/\/+$/, '');
function dirSegment(current, project, home) {
  const cur = norm(current);
  const proj = norm(project);
  if (proj && (cur === proj || cur.startsWith(proj + '/'))) {
    const base = proj.split('/').filter(Boolean).pop() || proj;
    const rel = cur.slice(proj.length).replace(/^\//, '');
    return rel ? `${base}/${rel}` : base;
  }
  let s = cur;
  const h = norm(home);
  if (h && s.toLowerCase().startsWith(h.toLowerCase())) s = '~' + s.slice(h.length);
  const parts = s.split('/').filter(Boolean);
  return parts.length > 3 ? '…/' + parts.slice(-3).join('/') : s || '~';
}

// --- git -------------------------------------------------------------------
// One cheap call gives branch + dirtiness. First line is "## branch...remote";
// any remaining lines mean uncommitted changes. Returns null outside a repo.
function gitInfo(cwd) {
  try {
    const out = execFileSync('git', ['status', '--porcelain=v1', '--branch'], {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 1000, // keep the bar snappy on slow repos
    });
    const lines = out.split('\n');
    const head = lines[0] || '';
    // Strip "## ", then the upstream ("...origin/x") and any "[ahead N]". A fresh
    // repo reads "## No commits yet on <branch>", so pull the name out of that too.
    let branch = head.replace(/^## /, '').replace(/^No commits yet on /, '');
    branch = branch.split('...')[0].split(' ')[0];
    if (head.includes('(no branch)') || branch === 'HEAD') branch = 'detached';
    const dirty = lines.slice(1).some((l) => l.trim() !== '');
    return { branch, dirty };
  } catch {
    return null; // not a repo, or git unavailable — just omit the segment
  }
}

// --- render ----------------------------------------------------------------
function render(input) {
  const home = os.homedir();
  const ws = input.workspace || {};
  const cwd = ws.current_dir || input.cwd || home;
  const segments = [];

  // Model — just the version number to save space, e.g. "Opus 4.8" -> "4.8".
  // The family is dropped: it's almost always Opus, and a bare initial only
  // confuses (capital "O" reads as 0). Version-agnostic on purpose — nothing
  // here is pinned to 4.x, so a future "Opus 5" or "Opus 4.10" just shows "5"
  // / "4.10" automatically. The pattern matches a whole dotted version
  // (digits and interior dots, no trailing dot); if a release ever ships a
  // name with no parseable version we fall back to showing it in full.
  const name = (input.model && input.model.display_name) || 'Claude';
  const m = name.match(/\d+(?:\.\d+)*/);
  let model = blue(m ? m[0] : name);

  // Thinking effort — the reasoning level for the turn (set via /effort or the
  // Tab cycle). Claude Code reports it as `effort.level`, one of
  // low|medium|high|xhigh|max (default high), and only for models that support
  // it — older ones omit the field, so guard and just skip the tag there.
  // Glued to the version with a grey dot ("4.8·max") so it reads as an
  // attribute of the model, not a separate segment. Colour ramps quiet→warm
  // with the level: the default sits calm (purple), the cheap end greys out,
  // and the slow/expensive top end (xhigh/max) warms up as a reminder it'll
  // think longer. Deliberately NOT the green→yellow→red ramp ctx/quota use —
  // a higher thinking level isn't a problem, just a louder setting.
  const lvl = input.effort && input.effort.level;
  if (lvl) {
    const label = { low: 'low', medium: 'med', high: 'high', xhigh: 'xhigh', max: 'max' };
    const levelTone = { low: grey, medium: green, high: purple, xhigh: yellow, max: red };
    model += grey('·') + (levelTone[lvl] || purple)(label[lvl] || lvl);
  }
  segments.push(model);

  // Directory — project-relative, cyan (matches the shell prompts).
  segments.push(cyan(dirSegment(cwd, ws.project_dir, home)));

  // Git — branch in purple, red * if dirty.
  const git = gitInfo(cwd);
  if (git) {
    segments.push(purple(' ' + git.branch) + (git.dirty ? red(' *') : ''));
  }

  // Context window — tokens used (out of the window size when known), coloured
  // by how full it is (green→yellow→red). e.g. "ctx 84k/200k".
  const ctx = input.context_window;
  if (ctx) {
    const size = ctx.context_window_size;
    const u = ctx.current_usage || {};
    let used = null;
    if (typeof ctx.used_percentage === 'number' && size) {
      used = Math.round((size * ctx.used_percentage) / 100);
    } else if (ctx.current_usage) {
      used = (u.input_tokens || 0) + (u.output_tokens || 0) +
        (u.cache_read_input_tokens || 0) + (u.cache_creation_input_tokens || 0);
    } else if (typeof ctx.total_input_tokens === 'number') {
      used = ctx.total_input_tokens + (ctx.total_output_tokens || 0);
    }
    if (used != null) {
      // Absolute thresholds, not %: Opus's 1M window is billed at flat pricing
      // (no long-context premium), so the concern is attention/quality as the
      // window fills, not cost. Red once context gets heavy (>100k), yellow >50k.
      const tone = used >= 100000 ? red : used >= 50000 ? yellow : green;
      const label = size ? `${fmtTokens(used)}/${fmtTokens(size)}` : fmtTokens(used);
      segments.push(grey('ctx ') + tone(label));
    }
  }

  // Plan usage — how much of the Pro/Max subscription limits is spent, so a
  // cap is visible before we hit it. `rate_limits` only appears for subscribers
  // after the first API response, and each window can be absent on its own, so
  // probe defensively. Here % *is* the right unit (it's a hard quota): green
  // normally, yellow past half, red once it's getting close.
  const rl = input.rate_limits;
  if (rl) {
    const usageTone = (p) => (p >= 80 ? red : p >= 50 ? yellow : green);
    const win = (w, label) => {
      const p = w && w.used_percentage;
      if (typeof p !== 'number') return;
      segments.push(grey(label + ' ') + usageTone(p)(Math.round(p) + '%'));
    };
    win(rl.five_hour, '5h');
    win(rl.seven_day, 'wk');
  }

  return segments.join(grey('  '));
}

// --- stdin plumbing --------------------------------------------------------
let data = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (c) => (data += c));
process.stdin.on('end', () => {
  let input = {};
  try {
    input = JSON.parse(data || '{}');
  } catch {
    /* empty/garbage stdin — fall back to defaults */
  }
  process.stdout.write(render(input));
});
