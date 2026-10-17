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
// `label` replaces the project's basename as the head (a worktree shows its
// main repo's name there, since its own folder name is in the wt segment).
function dirSegment(current, project, home, label) {
  const cur = norm(current);
  const proj = norm(project);
  if (proj && (cur === proj || cur.startsWith(proj + '/'))) {
    const base = label || proj.split('/').filter(Boolean).pop() || proj;
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
// --no-optional-locks so a bar refresh never fights a git command Claude is
// running in the same repo for index.lock. Returns null on any failure.
function runGit(cwd, args) {
  try {
    return execFileSync('git', ['--no-optional-locks', ...args], {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
      timeout: 1000, // keep the bar snappy on slow repos
    });
  } catch {
    return null;
  }
}

// One cheap call gives branch, dirtiness and distance from upstream. First line
// is "## branch...remote [ahead N, behind M]"; any remaining lines mean
// uncommitted changes. Returns null outside a repo.
function gitInfo(cwd) {
  const out = runGit(cwd, ['status', '--porcelain=v1', '--branch']);
  if (out === null) return null; // not a repo, or git unavailable — omit the segment
  const lines = out.split('\n');
  const head = lines[0] || '';
  // Strip "## ", then the upstream ("...origin/x") and any "[ahead N]". A fresh
  // repo reads "## No commits yet on <branch>", so pull the name out of that too.
  let branch = head.replace(/^## /, '').replace(/^No commits yet on /, '');
  branch = branch.split('...')[0].split(' ')[0];
  if (head.includes('(no branch)') || branch === 'HEAD') branch = 'detached';
  const dirty = lines.slice(1).some((l) => l.trim() !== '');
  const ahead = Number((head.match(/ahead (\d+)/) || [])[1] || 0);
  const behind = Number((head.match(/behind (\d+)/) || [])[1] || 0);
  return { branch, dirty, ahead, behind };
}

// The linked worktree cwd sits in, or null in the main checkout (or outside a
// repo). A linked worktree's git dir lives under the main repo's
// .git/worktrees/, so it differs from the shared common dir. `name` is the
// worktree's folder, which is what `git worktree add` and Claude call it;
// `repo` is the main checkout's folder, the parent of the common .git dir.
function worktreeInfo(cwd) {
  const out = runGit(cwd, ['rev-parse', '--path-format=absolute', '--show-toplevel', '--git-dir', '--git-common-dir']);
  if (out === null) return null;
  const [top, gitDir, commonDir] = out.trim().split('\n').map(norm);
  if (!gitDir || gitDir === commonDir) return null;
  const segs = commonDir.split('/');
  return { top, name: top.split('/').pop(), repo: segs[segs.length - 1] === '.git' ? segs[segs.length - 2] : null };
}

// Time until an epoch-seconds instant, compactly: "35m", "1h20m", "2d3h".
function fmtUntil(epochSec) {
  const mins = Math.max(0, Math.round((epochSec * 1000 - Date.now()) / 60000));
  if (mins < 60) return `${mins}m`;
  const h = Math.floor(mins / 60);
  if (h < 24) return `${h}h${String(mins % 60).padStart(2, '0')}m`;
  return `${Math.floor(h / 24)}d${h % 24}h`;
}

// --- render ----------------------------------------------------------------
function render(input) {
  const home = os.homedir();
  const ws = input.workspace || {};
  const cwd = ws.current_dir || input.cwd || home;
  const segments = [];

  // Model — family initial + version, e.g. "Opus 4.8" -> "O4.8", "Sonnet 5" ->
  // "S5". Used to be just the version ("4.8"), but now that several families
  // share version numbers (Sonnet 5, Fable 5, Haiku 4.5 vs Opus 4.8) a bare
  // number no longer says which model is running — the initial disambiguates.
  // Version-agnostic on purpose — nothing here is pinned to 4.x, so a future
  // "Opus 5" or "Sonnet 4.10" just shows "O5" / "S4.10" automatically. If a
  // release ever ships a name with no parseable version we fall back to
  // showing it in full.
  const name = (input.model && input.model.display_name) || 'Claude';
  const m = name.match(/^(\w)\S*\s+(\d+(?:\.\d+)*)/);
  let model = blue(m ? m[1] + m[2] : name);

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

  // Directory — project-relative, cyan (matches the shell prompts). Inside a
  // linked worktree it's headed by the main repo's name instead of the
  // worktree folder, so "which project" still reads and the wt segment says
  // which worktree.
  const git = gitInfo(cwd);
  const wt = git && worktreeInfo(cwd);
  segments.push(cyan(wt && wt.repo ? dirSegment(cwd, wt.top, home, wt.repo) : dirSegment(cwd, ws.project_dir, home)));

  // Git — branch in purple, red * if dirty, yellow ↑N/↓M against upstream.
  if (git) {
    segments.push(purple(' ' + git.branch) + (git.dirty ? red(' *') : '') +
      (git.ahead ? yellow(` ↑${git.ahead}`) : '') + (git.behind ? yellow(` ↓${git.behind}`) : ''));
  }

  // Worktree — only inside a linked one, so the main checkout stays quiet.
  if (wt) segments.push(grey('wt ') + cyan(wt.name));

  // Lines changed this session — green +added, red −removed; hidden at 0/0.
  const cost = input.cost || {};
  const added = cost.total_lines_added || 0;
  const removed = cost.total_lines_removed || 0;
  if (added || removed) segments.push(green(`+${added}`) + ' ' + red(`−${removed}`));

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
    // Once a window is half spent, add when it resets ("62% ⧖ 1h20m") — the
    // question at that point is whether there's room to keep going.
    const win = (w, label) => {
      const p = w && w.used_percentage;
      if (typeof p !== 'number') return;
      const reset = p >= 50 && typeof w.resets_at === 'number' ? grey(' ⧖ ' + fmtUntil(w.resets_at)) : '';
      segments.push(grey(label + ' ') + usageTone(p)(Math.round(p) + '%') + reset);
    };
    win(rl.five_hour, '5h');
    win(rl.seven_day, 'wk');
  }

  // Session cost — only without plan limits, i.e. on API billing. On Pro/Max
  // it's a list-price estimate of money not actually spent; the 5h/wk usage
  // above is what counts there.
  if (!rl && typeof cost.total_cost_usd === 'number') {
    segments.push(grey('$' + cost.total_cost_usd.toFixed(2)));
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
