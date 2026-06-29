// Tests for the drill runner's pure internals. No interactive input, no extra
// dependency — run with: node --test drills/
//
// loadDeck takes an optional path so we can point it at a temp fixture instead of
// the real deck; sessionCards is pure. Between them they cover parsing (including
// the new origin/category columns), malformed-row skipping, a missing file, and the
// category filter.

const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const { loadDeck, sessionCards, categoryChoices, FIELDS } = require('./drill.js');

// Write a TSV (header + given body lines) to a unique temp file and return its path.
// pid keeps the name unique without Math.random/Date, which suffices for a test run.
let seq = 0;
function fixture(bodyLines) {
  const file = path.join(os.tmpdir(), `drill-deck-${process.pid}-${seq++}.tsv`);
  const text = [FIELDS.join('\t'), ...bodyLines].join('\n') + '\n';
  fs.writeFileSync(file, text);
  return file;
}

const row = (id, tool, task, reveal, origin, category) =>
  [id, tool, task, reveal, origin, category].join('\t');

test('loadDeck parses every field including origin and category', () => {
  const file = fixture([
    row('a', 'WezTerm', 'task A', 'reveal A', 'custom', 'panes'),
    row('b', 'zoxide', 'task B', 'reveal B', 'builtin', 'navigation'),
  ]);
  const cards = loadDeck(file);
  assert.equal(cards.length, 2);
  assert.deepEqual(cards[0], {
    id: 'a', tool: 'WezTerm', task: 'task A', reveal: 'reveal A',
    origin: 'custom', category: 'panes',
  });
  assert.equal(cards[1].origin, 'builtin');
  assert.equal(cards[1].category, 'navigation');
});

test('loadDeck skips malformed rows (wrong column count or blank field)', () => {
  const file = fixture([
    row('ok', 'zsh', 'task', 'reveal', 'custom', 'editing'),
    'too\tfew\tcolumns',                                  // wrong column count
    row('blank', 'zsh', 'task', '', 'custom', 'history'), // blank required field
    row('ok2', 'niri', 'task', 'reveal', 'custom', 'windows'),
  ]);
  const cards = loadDeck(file);
  assert.deepEqual(cards.map((c) => c.id), ['ok', 'ok2']);
});

test('loadDeck returns [] for a missing deck file', () => {
  const missing = path.join(os.tmpdir(), `drill-deck-does-not-exist-${process.pid}.tsv`);
  assert.deepEqual(loadDeck(missing), []);
});

test('sessionCards with no category returns the whole deck', () => {
  const deck = loadDeck(fixture([
    row('a', 'WezTerm', 't', 'r', 'custom', 'panes'),
    row('b', 'niri', 't', 'r', 'custom', 'windows'),
  ]));
  assert.equal(sessionCards(deck).length, 2);
});

test('sessionCards filters by category, case-insensitively', () => {
  const deck = loadDeck(fixture([
    row('a', 'WezTerm', 't', 'r', 'custom', 'panes'),
    row('b', 'niri', 't', 'r', 'custom', 'windows'),
    row('c', 'WezTerm', 't', 'r', 'custom', 'panes'),
  ]));
  const panes = sessionCards(deck, 'PANES');
  assert.deepEqual(panes.map((c) => c.id), ['a', 'c']);
});

test('sessionCards returns nothing for an unknown category', () => {
  const deck = loadDeck(fixture([
    row('a', 'WezTerm', 't', 'r', 'custom', 'panes'),
  ]));
  assert.deepEqual(sessionCards(deck, 'nope'), []);
});

test('categoryChoices leads with All, then orders by count then name', () => {
  const deck = loadDeck(fixture([
    row('a', 'WezTerm', 't', 'r', 'custom', 'panes'),
    row('b', 'niri', 't', 'r', 'custom', 'windows'),
    row('c', 'WezTerm', 't', 'r', 'custom', 'panes'),
    row('d', 'zsh', 't', 'r', 'custom', 'editing'),
  ]));
  const choices = categoryChoices(deck);
  // All entry first, carrying the full deck count and a null category.
  assert.deepEqual(choices[0], { name: null, label: 'All categories', count: 4 });
  // panes (2) outranks the singletons; editing < windows breaks the count tie.
  assert.deepEqual(
    choices.slice(1).map((c) => [c.name, c.count]),
    [['panes', 2], ['editing', 1], ['windows', 1]]
  );
});

test('categoryChoices on an empty deck is just the (empty) All entry', () => {
  assert.deepEqual(categoryChoices([]), [{ name: null, label: 'All categories', count: 0 }]);
});
