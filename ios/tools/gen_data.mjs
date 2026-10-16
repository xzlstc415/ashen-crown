#!/usr/bin/env node
// Extracts card/class/opponent data and the SVG art from src/game.html (the web game) into
//   ios/Ruinaccord/Resources/GameData.json
//   ios/Ruinaccord/Assets.xcassets/Art/*.imageset  (one vector image per card and class)
// Run after changing cards in the web game:  node ios/tools/gen_data.mjs
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const html = fs.readFileSync(path.join(root, 'src', 'game.html'), 'utf8');
const start = html.indexOf('// ---------- card art ----------');
const end = html.indexOf('const CBY=');
if (start < 0 || end < 0) throw new Error('markers not found in game.html');
const chunk = html.slice(start, end);
const data = new Function(chunk + '\nreturn {ART, CARDS, OPP, CLASSES, BOARD_MAX};')();

// ---- JSON ----
const cards = Object.entries(data.CARDS).map(([id, c]) => ({
  id, cost: c.c, type: c.t, atk: c.a ?? null, hp: c.h ?? null, rarity: c.r, race: c.race ?? null,
  guard: !!c.guard, ward: !!c.ward, surge: !!c.surge, gasp: c.gasp ?? null, token: !!c.token,
  cls: c.cls ?? null, text: c.x ?? null, sp: c.sp ?? 0, onSpell: c.onSpell ?? null,
  bc: fx(c.bc), fx: fx(c.fx), names: c.n, flavor: c.f,
}));
function fx(e) {
  if (!e) return null;
  return {
    dmg: e.dmg ?? 0, aoe: e.aoe ?? 0, face: e.face ?? 0, healT: e.healT ?? 0, heal: e.heal ?? 0, armor: e.armor ?? 0,
    draw: e.draw ?? 0, mana: e.mana ?? 0, selfDmg: e.selfDmg ?? 0, guard: !!e.guard, ward: !!e.ward,
    buff: e.buff ?? null, team: e.team ?? null, summon: e.summon ? [].concat(e.summon) : [], tgt: e.tgt ?? null,
    cond: e.cond ?? null, destroy: !!e.destroy, silence: !!e.silence, freeze: !!e.freeze, freezeAll: !!e.freezeAll,
    setAtk: e.setAtk ?? 0, setHp: e.setHp ?? 0, sweep: e.sweep ?? 0, heroes: !!e.heroes, armorDmg: !!e.armorDmg,
    dmgBeast: e.dmgBeast ?? 0, drawIfKill: !!e.drawIfKill, tempAtk: e.tempAtk ?? 0, bounce: !!e.bounce, perFoe: e.perFoe ?? null,
  };
}
const classes = data.CLASSES.map(c => ({
  id: c.id, color: c.col, names: c.n, tags: c.tag, deck: c.deck,
  power: {cost: c.power.c, tgt: c.power.tgt ?? null, fx: fx(c.power.fx), names: c.power.n},
}));
const opponents = data.OPP.map(o => ({names: o.n, initials: o.i, hp: o.hp, deck: o.deck}));
const out = {cards, classes, opponents, boardMax: data.BOARD_MAX, deckSize: 25,
  fortify: {cost: 2, tgt: null, fx: fx({armor: 2}), names: ['Fortify', '固守', '防備']}};
const resDir = path.join(root, 'ios', 'Ruinaccord', 'Resources');
fs.mkdirSync(resDir, {recursive: true});
fs.writeFileSync(path.join(resDir, 'GameData.json'), JSON.stringify(out, null, 1));

// ---- SVG art -> asset catalog ----
// Xcode's asset compiler does not accept 8-digit hex colours; split them into colour + opacity.
function fixColors(svg) {
  return svg.replace(/(fill|stroke)="#([0-9a-fA-F]{6})([0-9a-fA-F]{2})"/g, (m, attr, rgb, a) =>
    `${attr}="#${rgb}" ${attr}-opacity="${(parseInt(a, 16) / 255).toFixed(3)}"`);
}
const artDir = path.join(root, 'ios', 'Ruinaccord', 'Assets.xcassets', 'Art');
fs.rmSync(artDir, {recursive: true, force: true});
fs.mkdirSync(artDir, {recursive: true});
fs.writeFileSync(path.join(artDir, 'Contents.json'), JSON.stringify({info: {author: 'xcode', version: 1}, properties: {'provides-namespace': false}}, null, 2));
function writeImage(name, viewBox, body) {
  const dir = path.join(artDir, `${name}.imageset`);
  fs.mkdirSync(dir);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">${fixColors(body)}</svg>\n`;
  fs.writeFileSync(path.join(dir, `${name}.svg`), svg);
  fs.writeFileSync(path.join(dir, 'Contents.json'), JSON.stringify({
    images: [{filename: `${name}.svg`, idiom: 'universal'}],
    info: {author: 'xcode', version: 1},
    properties: {'preserves-vector-representation': true},
  }, null, 2));
}
let n = 0;
for (const [k, body] of Object.entries(data.ART)) { writeImage(`art_${k}`, '0 0 100 64', body); n++; }
for (const c of data.CLASSES) { writeImage(`class_${c.id}`, '18 0 64 64', c.art); n++; }
console.log(`wrote GameData.json (${cards.length} cards, ${classes.length} classes, ${opponents.length} foes) and ${n} images`);
