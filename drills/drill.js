#!/usr/bin/env node
// `learn` — a flashcard drill runner for this repo's own tools.
//
// One cross-platform Node script (Node is already in the stack via Claude Code, so
// no new runtime — same reasoning as claude/statusline.js). It reads the curated
// deck in deck.tsv and runs a session: show a task, let you attempt it in the real
// tool, reveal the answer on a keypress, and tally a self-grade. There is no
// scheduling and no saved state — every card is fair game every session, and you
// pull a session whenever you want.
//
//   node drill.js               pick a category from an interactive menu, then drill
//   node drill.js <category>    skip the menu and drill that category directly
//
// With no category and an interactive terminal, the runner shows an arrow-key menu
// of categories (each with its card count, plus an "All" entry) so you choose a
// focused set instead of skimming the whole deck — this is what keeps it usable as
// the deck grows. Piped/non-interactive runs (and `<category>`) skip the menu.

const fs = require('node:fs');
const path = require('node:path');

// --- presentation ------------------------------------------------------------
// ANSI styling, gated on an interactive, color-permitting terminal so piped output
// and NO_COLOR runs stay plain (the same isTTY guard the menu already relied on, and
// modern Windows Terminal/WezTerm honor these codes — one path for both OSes). Each
// helper wraps a string in an SGR code + reset, or returns it untouched when color is
// off. Apply color AFTER any padEnd so the escape codes don't throw off alignment.
const COLOR = process.stdout.isTTY && !process.env.NO_COLOR;
const sgr = (code) => (s) => (COLOR ? `\x1b[${code}m${s}\x1b[0m` : `${s}`);
const dim = sgr('2');
const bold = sgr('1');
const green = sgr('32');
const cyan = sgr('36');
const red = sgr('31');

// Clear the screen and home the cursor so each card lands like a fresh flashcard
// instead of scrolling the previous ones away. A no-op off-TTY, so piped runs just
// print sequentially as before.
function clearScreen() {
  if (COLOR) process.stdout.write('\x1b[2J\x1b[H');
}

// A unicode meter: `done` of `total` cells filled. Sits in the card header so progress
// reads at a glance, not only as "4/17".
function progressBar(done, total, width = 14) {
  const filled = total ? Math.round((done / total) * width) : 0;
  return green('█'.repeat(filled)) + dim('░'.repeat(width - filled));
}

// Fisher–Yates, in place. Shuffling each interactive session keeps order from becoming
// a crutch (you recall the answer, not "the third card"). Off-TTY runs skip it so
// scripted output stays deterministic.
function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

// The deck's columns, in order. A row must supply a non-empty value for every one of
// these or it's skipped (see loadDeck) — a half-filled card is an authoring mistake.
const FIELDS = ['id', 'tool', 'task', 'reveal', 'origin', 'category'];

// --- deck --------------------------------------------------------------------
// Parse a deck TSV into card objects. The path defaults to the deck next to this
// script (resolved relative to it, not the cwd); tests pass a fixture path.
// Robust by design so a broken deck never crashes a session: a missing/unreadable/
// empty file yields [], and any row without all FIELDS non-empty (wrong column
// count, blank field) is skipped rather than aborting.
function loadDeck(deckPath = path.join(__dirname, 'deck.tsv')) {
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

// --- selection ---------------------------------------------------------------
// Cards for a session: the whole deck, optionally narrowed to a single category
// (exact, case-insensitive). No category -> every card.
function sessionCards(deck, category) {
  const want = category ? category.trim().toLowerCase() : null;
  return deck.filter((card) => !want || card.category.toLowerCase() === want);
}

// --- category menu -----------------------------------------------------------
// The menu's rows, derived from the deck: an "All" entry (category null) on top,
// then each distinct category with its card count, ordered by count (most cards
// first) then name so the meatiest topics surface at the top. Pure, so it's the
// part the test exercises — the interactive rendering below is not unit-tested
// (same reasoning as getKey/runSession).
function categoryChoices(deck) {
  const counts = new Map();
  for (const card of deck) counts.set(card.category, (counts.get(card.category) || 0) + 1);
  const cats = [...counts.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .map(([name, count]) => ({ name, label: name, count }));
  return [{ name: null, label: 'All categories', count: deck.length }, ...cats];
}

// Draw the category menu in place (clearing each line) and drive it with the
// keyboard until the user starts a session or cancels. ↑/↓ (or k/j) move the
// cursor, Enter starts the highlighted category, q/Esc cancels. Returns
// { category } (null = whole deck) or { cancelled: true }.
async function chooseCategory(deck) {
  const choices = categoryChoices(deck);
  // Pad labels so the counts line up in a column regardless of name length.
  const width = Math.max(...choices.map((c) => c.label.length));
  let sel = 0;
  let drawn = 0; // lines written by the previous frame, so we can redraw over them
  for (;;) {
    const lines = [dim('🎴 Pick a category to drill — ↑/↓ move · Enter start · q quit')];
    choices.forEach((c, i) => {
      const active = i === sel;
      const label = c.label.padEnd(width); // pad first, color after — codes aren't width
      lines.push(
        `  ${active ? cyan('▸') : ' '} ${active ? cyan(bold(label)) : label}  ${dim(`(${c.count})`)}`
      );
    });
    if (drawn) process.stdout.write(`\x1b[${drawn}A`); // jump back to the frame's top
    for (const line of lines) process.stdout.write(`\x1b[2K${line}\n`); // clear + write
    drawn = lines.length;

    const k = await getKey();
    if (k === 'q' || k === '\x1b') return { cancelled: true };
    if (k === '\x1b[A' || k === 'k') sel = (sel - 1 + choices.length) % choices.length;
    else if (k === '\x1b[B' || k === 'j') sel = (sel + 1) % choices.length;
    else if (k === '\r' || k === '\n') return { category: choices[sel].name };
  }
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

  // No explicit category and an interactive terminal: let the user pick one from
  // the menu rather than skimming the whole deck. Non-interactive runs (piped, the
  // test) fall through to the whole deck, preserving the old scriptable behavior.
  if (category == null && deck.length > 0 && process.stdin.isTTY) {
    const choice = await chooseCategory(deck);
    if (choice.cancelled) {
      console.log('\n🎴 Cancelled — no drills run.\n');
      return;
    }
    category = choice.category; // null => the whole deck (the "All" entry)
  }

  const cards = sessionCards(deck, category);
  const scope = category ? ` in [${category}]` : '';

  if (cards.length === 0) {
    const why = category ? ' — no cards in that category' : ' — the deck is empty';
    console.log(`\n🎴 Nothing to drill${scope}${why}.\n`);
    return;
  }

  // Interactive sessions get a fresh, shuffled order each run; off-TTY runs keep deck
  // order so scripted output stays stable (shuffle() is a no-op-equivalent there).
  const order = COLOR ? shuffle([...cards]) : cards;

  // Counters for the live tally and end-of-session summary.
  let gotIt = 0;
  let missed = 0;
  let skipped = 0;
  let quit = false;
  for (let i = 0; i < order.length && !quit; i++) {
    const card = order[i];
    clearScreen();
    // Header: the facets the filter doesn't already imply — the owning tool and whether
    // the feature is this repo's config or a tool default (origin) — on the left; a
    // progress meter and count on the right. The category equals the tool, so it's not
    // repeated.
    const headMeta = `${bold(card.tool)} ${dim('·')} ${dim(card.origin)}`;
    const headProg = `${progressBar(i, order.length)} ${dim(`${i + 1}/${order.length}`)}`;
    console.log(`\n🎴  ${headMeta}    ${headProg}\n`);
    console.log(`  ${bold(card.task)}\n`);
    process.stdout.write(dim('  ↳ press any key to reveal · q to quit … '));
    let k = await getKey();
    if (k === 'q') { quit = true; break; }

    console.log(`\n\n  ${green('✓')} ${card.reveal}\n`);
    // Grade keys colored to match their meaning, with the running tally on the right.
    const tally = `${green(`✓${gotIt}`)} ${red(`✗${missed}`)} ${dim(`⤼${skipped}`)}`;
    process.stdout.write(
      `  ${green('g')} got it   ${red('m')} missed   ${dim('s')} skip   ${dim('q')} quit` +
        `      ${tally}\n  … `
    );
    // Loop until a recognized action is pressed; anything else (arrow keys and other
    // multi-byte escape sequences included) is ignored rather than mistaken for a grade.
    for (;;) {
      k = await getKey();
      if (k === 'q') { quit = true; break; }
      if (k === 's') { skipped++; break; }
      if (k === 'g') { gotIt++; break; }
      if (k === 'm') { missed++; break; }
    }
  }

  const reviewed = gotIt + missed;
  console.log(
    `\n🎴 Reviewed ${bold(reviewed)} ` +
      `(${green(`${gotIt} got it`)} · ${red(`${missed} missed`)} · ${dim(`${skipped} skipped`)}) ` +
      `of ${order.length}${scope}.\n`
  );
}

// --- entry -------------------------------------------------------------------
function main() {
  const args = process.argv.slice(2);
  // The first non-flag argument, if any, restricts the session to that category.
  const category = args.find((a) => !a.startsWith('-'));
  runSession(category).catch((err) => {
    console.error(`learn: ${err.message}`);
    process.exit(1);
  });
}

// Run only when invoked directly; when required (tests) just expose the internals.
if (require.main === module) main();

module.exports = { loadDeck, sessionCards, categoryChoices, FIELDS };
