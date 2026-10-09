#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Verify the balance fix: level-aware health scaling + reduced vampiric."""

# creature_classlevelstats.sql, class WARRIOR
LEVELS = {
    20: dict(hp=484, dmg=9.6823, ap=70),
    35: dict(hp=1220, dmg=15.8617, ap=118),
    40: dict(hp=1524, dmg=18.2971, ap=136),
    45: dict(hp=1848, dmg=24.6797, ap=184),
    60: dict(hp=4979, dmg=53.4755, ap=252),
    80: dict(hp=12600, dmg=164.924, ap=642),
}

ATTACK_TIME = 2000
CRIT = 0.05
CRIT_MULT = 2.0

OLD_HP_LADDER = [1.5, 2.0, 3.0, 4.5, 6.0]
DMG_LADDER = [1.15, 1.30, 1.50, 1.70, 2.00]
REFERENCE_LEVEL = 80
SAVAGE, ENRAGED = 1.25, 1.50
VAMPIRIC_PCT = 0.25      # new default
REGEN_PCT = 3.0
REGEN_INTERVAL_MS = 5000


def level_factor(level):
    return min(max(level / REFERENCE_LEVEL, 0.15), 1.0)


def hp_mult(rank, level):
    ladder = OLD_HP_LADDER[rank - 1]
    return 1.0 + (ladder - 1.0) * level_factor(level)


def nem(level, rank):
    s = LEVELS[level]
    asm = ATTACK_TIME / 1000.0
    ap = s["ap"] / 14.0
    lo = (s["dmg"] * DMG_LADDER[rank - 1] + ap) * asm
    hi = (s["dmg"] * 1.5 * DMG_LADDER[rank - 1] + ap) * asm
    avg = (lo + hi) / 2
    dps = avg / (ATTACK_TIME / 1000.0) * (1 + CRIT * (CRIT_MULT - 1))
    return dict(hp=s["hp"] * hp_mult(rank, level), avg=avg, dps=dps)


def reduction(armor, attacker_level):
    lvl = attacker_level
    if lvl > 59:
        lvl = lvl + 4.5 * (lvl - 59)
    t = 0.1 * armor / (8.5 * lvl + 40)
    return min(t / (1 + t), 0.75)


print("=" * 84)
print("A. HEALTH MULTIPLIER AFTER THE FIX (reference level 80)")
print("=" * 84)
print(f"  {'level':>6} | {'factor':>7} | " + " | ".join(f"rank {r} x" for r in range(1, 6)))
for lvl in (20, 35, 40, 45, 60, 80):
    row = f"  {lvl:>6} | {level_factor(lvl):>7.2f} | "
    row += " | ".join(f"{hp_mult(r, lvl):>7.2f}" for r in range(1, 6))
    print(row)

print()
print("=" * 84)
print("B. LEVEL 40 — BEFORE vs AFTER (player: 1600 HP, 2400 armour, ~120 DPS)")
print("=" * 84)
print(f"  {'rank':>4} | {'HP before':>9} {'HP after':>9} | {'req DPS before':>14} {'req DPS after':>13} | {'verdict after':>14}")
for r in range(1, 6):
    s = LEVELS[40]
    before_hp = s["hp"] * OLD_HP_LADDER[r - 1]
    after_hp = s["hp"] * hp_mult(r, 40)
    dps = nem(40, r)["dps"]
    req_b = before_hp * dps / 1600
    req_a = after_hp * dps / 1600
    verdict = "win" if req_a < 120 else ("needs help" if req_a < 200 else "hopeless")
    print(f"  {r:>4} | {before_hp:>9,.0f} {after_hp:>9,.0f} | {req_b:>14.0f} {req_a:>13.0f} | {verdict:>14}")

print()
print("=" * 84)
print("C. LEVEL 40 rank 5 — full fight, after the fix")
print("=" * 84)
n = nem(40, 5)
red = reduction(2400, 40)
hit = n["avg"] * (1 - red)
taken = hit / (ATTACK_TIME / 1000.0)
regen_hps = n["hp"] * REGEN_PCT / 100.0 / (REGEN_INTERVAL_MS / 1000.0)
vamp_hps = hit * VAMPIRIC_PCT / (ATTACK_TIME / 1000.0)
print(f"  nemesis HP {n['hp']:,.0f}, hit {hit:.0f} after {red*100:.1f}% armour ({taken:.1f} DPS)")
print(f"  player dies in          : {1600/taken:>5.0f}s")
print(f"  nemesis dies in         : {n['hp']/120:>5.0f}s   -> {'PLAYER WINS' if n['hp']/120 < 1600/taken else 'player loses'}")
print(f"  + Savage+Enraged        : player dies in {1600/(hit*SAVAGE*ENRAGED/2.0):>5.0f}s")
print(f"  + Vampiric(25%)+Regen   : heals {vamp_hps+regen_hps:.0f} hps -> nemesis dies in {n['hp']/max(120-vamp_hps-regen_hps,1):>5.0f}s")
print(f"  max single hit          : {n['avg']*2*(1-red)*SAVAGE*ENRAGED*CRIT_MULT:.0f}")

print()
print("=" * 84)
print("D. LEVEL 80 — unchanged (reference level)")
print("=" * 84)
for r in (1, 5):
    n = nem(80, r)
    req = n["hp"] * n["dps"] / 20000
    print(f"  rank {r}: HP {n['hp']:>8,.0f} (was {LEVELS[80]['hp']*OLD_HP_LADDER[r-1]:>8,.0f}), required DPS {req:>6.0f}, player 2500 -> WIN")

print()
print("=" * 84)
print("E. LOW-LEVEL SANITY (rank 5)")
print("=" * 84)
for lvl, php, pdps in ((20, 700, 55), (35, 1300, 100), (60, 3000, 400)):
    n = nem(lvl, 5)
    red = reduction(1800, lvl)
    taken = n["avg"] * (1 - red) / (ATTACK_TIME / 1000.0)
    req = n["hp"] * n["dps"] / php
    print(f"  level {lvl}: HP {n['hp']:>7,.0f} ({hp_mult(5, lvl):.2f}x), required {req:>6.0f} DPS vs actual ~{pdps} "
          f"-> {'win' if pdps > req else 'loses'}")
