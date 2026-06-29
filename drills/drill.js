#!/usr/bin/env node
// `learn` — a spaced-repetition drill runner for this repo's own tools.
//
// One cross-platform Node script (Node is already in the stack via Claude Code, so
// no new runtime — same reasoning as claude/statusline.js). It reads the curated
// deck in deck.tsv, shows the cards that are *due*, lets you attempt each one in the
// real tool, reveals the answer on a keypress, and records a self-grade. Scheduling
// is plain Leitner boxes; progress lives in a per-machine state file outside git.
//
//   node drill.js               run a drill session over every due card
//   node drill.js <category>    run a session restricted to one category
//   node drill.js --count       print only the number of due cards (for the shell nudge)

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const MS_PER_DAY = 86400000;
// Leitner boxes 1..5 -> days until the card is due again after a correct answer.
// A "got it" advances one box (longer interval); a "missed" drops back to box 1.
const INTERVALS = { 1: 1, 2: 3, 3: 7, 4: 21, 5: 60 };
const MAX_BOX = 5;

// The deck's columns, in order. A row must supply a non-empty value for every one of
// these or it's skipped (see loadDeck) — a half-filled card is an authoring mistake.
const FIELDS = ['id', 'tool', 'task', 'reveal', 'origin', 'category'];

// --- dates: store due as YYYY-MM-DD so plain string compare == date compare ------
const todayYMD = () => new Date().toISOString().slice(0, 10);
const addDaysYMD = (days) =>
  new Date(Date.now() + days * MS_PER_DAY).toISOString().slice(0, 10);

// --- deck --------------------------------------------------------------------
// Parse deck.tsv (resolved relative to this script, not the cwd) into card objects.
// Robust by design so a broken deck never crashes a session or the shell nudge:
// a missing/unreadable/empty file yields [], and any row without all FIELDS
// non-empty (wrong column count, blank field) is skipped rather than aborting.
function loadDeck() {
  const deckPath = path.join(__dirname, 'deck.tsv');
  let text;
  try {
    text = fs.readFileSync(deckPath, 'utf8');
  } catch {
    return []; // missing or unreadable deck -> nothing to drill
  }
  const lines = text.split(/\r?\n/).filter((l) => l.trim() !== '');
  const rows = lines.slice(1); // drop the header row
  const cards = [];
  for (const line of rows) {
    const cells = line.split('\t');
    if (cells.length !== FIELDS.length) continue; // wrong column count -> skip
    if (cells.some((c) => c.trim() === '')) continue; // blank required field -> skip
    const card = {};
    FIELDS.forEach((f, i) => (card[f] = cells[i]));
    cards.push(card);
  }
  return cards;
}

// --- per-machine progress state ----------------------------------------------
// Linux/mac: $XDG_STATE_HOME or ~/.local/state ; Windows: %LOCALAPPDATA%.
// Mirrors where D5 in design.md says progress should live. Gitignored, never shared.
function stateFile() {
  const base =
    process.platform === 'win32'
      ? process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local')
      : process.env.XDG_STATE_HOME || path.join(os.homedir(), '.local', 'state');
  return path.join(base, 'dotfiles-drills', 'progress.json');
}

function loadProgress() {
  try {
    const data = JSON.parse(fs.readFileSync(stateFile(), 'utf8'));
    // Guard against a file that parses but isn't an object (e.g. "null", "[]", "5").
    return data && typeof data === 'object' && !Array.isArray(data) ? data : {};
  } catch {
    return {}; // missing or corrupt -> start fresh
  }
}

function saveProgress(progress) {
  const file = stateFile();
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(progress, null, 2) + '\n');
}

// --- scheduling --------------------------------------------------------------
// A card is due if it's never been seen, or its next-due date has arrived.
const isDue = (card, progress) => {
  const p = progress[card.id];
  return !p || p.due <= todayYMD();
};

// Due cards, optionally narrowed to a single category (exact, case-insensitive).
function dueCards(deck, progress, category) {
  const want = category ? category.trim().toLowerCase() : null;
  return deck.filter(
    (card) =>
      isDue(card, progress) &&
      (!want || card.category.toLowerCase() === want)
  );
}

// Apply a grade to one card and return its new {box, due}.
function grade(card, progress, gotIt) {
  const prev = progress[card.id];
  const box = gotIt ? Math.min((prev?.box || 0) + 1, MAX_BOX) : 1;
  // got it -> push out by the box's interval; missed -> due again today (resurfaces
  // next session). Either way the card leaves the current session.
  const due = gotIt ? addDaysYMD(INTERVALS[box]) : todayYMD();
  return { box, due };
}

// --- interactive input -------------------------------------------------------
// Read a single keypress in raw mode. Ctrl+C / `q` exit cleanly.
function getKey() {
  return new Promise((resolve) => {
    const stdin = process.stdin;
    if (stdin.setRawMode) stdin.setRawMode(true);
    stdin.resume();
    stdin.once('data', (data) => {
      if (stdin.setRawMode) stdin.setRawMode(false);
      stdin.pause();
      const s = data.toString();
      if (s.charCodeAt(0) === 3) process.exit(0);
      resolve(s);
    });
  });
}

// --- session -----------------------------------------------------------------
async function runSession(category) {
  const deck = loadDeck();
  const progress = loadProgress();
  const due = dueCards(deck, progress, category);
  const scope = category ? ` in [${category}]` : '';

  if (due.length === 0) {
    console.log(`\n🎴 Nothing due${scope} — you're all caught up. Come back later.\n`);
    return;
  }

  console.log(
    `\n🎴 ${due.length} drill${due.length === 1 ? '' : 's'} due${scope}. ` +
      'Try each one in the real tool first, then reveal.\n'
  );

  // Counters for the end-of-session summary.
  let gotIt = 0;
  let missed = 0;
  let skipped = 0;
  let quit = false;
  for (let i = 0; i < due.length && !quit; i++) {
    const card = due[i];
    // Header carries the two new facets: which topic the card belongs to (category)
    // and whether the feature is this repo's config or a tool default (origin).
    console.log(`── ${i + 1}/${due.length}  [${card.tool} · ${card.category} · ${card.origin}]`);
    console.log(`   ${card.task}`);
    process.stdout.write('   ↳ press any key to reveal · q to quit … ');
    let k = await getKey();
    if (k === 'q') { quit = true; break; }

    console.log(`\n   ✓ ${card.reveal}`);
    process.stdout.write('   got it? (g = got it · m = missed · s = skip · q = quit) … ');
    // Loop until a recognized action is pressed; anything else (arrow keys and other
    // multi-byte escape sequences included) is ignored rather than mistaken for a grade.
    for (;;) {
      k = await getKey();
      if (k === 'q') { quit = true; break; }
      if (k === 's') {
        // Skip: leave the card's box/due untouched so its schedule is unchanged.
        skipped++;
        console.log('skipped — schedule unchanged\n');
        break;
      }
      if (k === 'g' || k === 'm') {
        progress[card.id] = grade(card, progress, k === 'g');
        if (k === 'g') { gotIt++; console.log('got it ✓\n'); }
        else { missed++; console.log('missed — back to box 1\n'); }
        break;
      }
    }
  }

  saveProgress(progress);
  const reviewed = gotIt + missed;
  const left = dueCards(deck, progress, category).length;
  console.log(
    `Reviewed ${reviewed} (${gotIt} got it · ${missed} missed · ${skipped} skipped). ` +
      `${left} due remaining${scope}${left ? ' — run learn again' : ' — all clear'}.\n`
  );
}

// --- entry -------------------------------------------------------------------
function countDue() {
  // For the shell-start nudge: print just the number, and never throw — any error
  // (missing deck, unreadable state) prints 0 so the nudge stays silent. The count is
  // always global (every due card), never per-category.
  try {
    console.log(dueCards(loadDeck(), loadProgress()).length);
  } catch {
    console.log(0);
  }
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--count')) {
    countDue();
    return;
  }
  // The first non-flag argument, if any, restricts the session to that category.
  const category = args.find((a) => !a.startsWith('-'));
  runSession(category).catch((err) => {
    console.error(`learn: ${err.message}`);
    process.exit(1);
  });
}

// Run only when invoked directly; when required (tests) just expose the internals.
if (require.main === module) main();

module.exports = { loadDeck, grade, dueCards, isDue, addDaysYMD, todayYMD, INTERVALS };
