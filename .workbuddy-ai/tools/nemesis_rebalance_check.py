#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sustain + rebalance analysis for a rank-5 nemesis (level-80 mob)."""

CLS_BASE_DAMAGE = 164.924
CLS_ATTACK_POWER = 642
CLS_BASE_HP = 12600
ATTACK_TIME = 2000
AP_TERM = CLS_ATTACK_POWER / 14.0

HEALTH_MULT = 6.0
DAMAGE_MULT = 2.0
SAVAGE, ENRAGED = 1.25, 1.50
VAMPIRIC_PCT = 0.50
REGEN_PCT = 3.0
REGEN_INTERVAL_MS = 5000

weapon_min = CLS_BASE_DAMAGE
weapon_max = CLS_BASE_DAMAGE * 1.5


def raw(dm, dmult=DAMAGE_MULT, at=ATTACK_TIME):
    asm = at / 1000.0
    return ((weapon_min * dmult + AP_TERM) * dm * asm,
            (weapon_max * dmult + AP_TERM) * dm * asm)


def reduction(armor, lvl=80):
    if lvl > 59:
        lvl = lvl + 4.5 * (lvl - 59)
    t = 0.1 * armor / (8.5 * lvl + 40)
    return min(t / (1 + t), 0.75)


hp = CLS_BASE_HP * HEALTH_MULT
lo, hi = raw(1.0)
avg = (lo + hi) / 2
dps = avg / (ATTACK_TIME / 1000.0)
regen_hps = hp * REGEN_PCT / 100.0 / (REGEN_INTERVAL_MS / 1000.0)

print("=" * 74)
print("VAMPIRIC — heals 50% of the damage actually dealt (AFTER armor)")
print("=" * 74)
print(f"  nemesis HP pool: {hp:,.0f}   Regenerating: {regen_hps:,.0f} hps")
print()
print(f"  {'target armor':>13} | {'affix':>10} | {'hit':>6} | {'heal/hit':>9} | {'vampiric hps':>12} | {'total hps':>9}")
for armor in (2500, 9000, 14000):
    red = reduction(armor)
    for label, mult in (("none", 1.0), ("S+E", SAVAGE * ENRAGED)):
        hit = avg * (1 - red) * mult
        vhps = hit * VAMPIRIC_PCT / (ATTACK_TIME / 1000.0)
        print(f"  {armor:>13,} | {label:>10} | {hit:>6.0f} | {hit*VAMPIRIC_PCT:>9.0f} | {vhps:>12.0f} | {vhps+regen_hps:>9.0f}")

print()
print("=" * 74)
print("EFFECTIVE DURABILITY vs a solo level-80 player")
print("=" * 74)
print(f"  nemesis deals {dps:,.0f} DPS -> a 20 000 HP player dies in {20000/dps:,.0f}s")
print()
print(f"  {'player DPS':>11} | {'no sustain':>11} | {'Regen only':>11} | {'Regen+Vampiric (plate)':>23}")
for pdps in (800, 1500, 2500, 5000):
    t0 = hp / pdps
    t1 = hp / max(pdps - regen_hps, 1)
    vamp_plate = avg * (1 - reduction(14000)) * VAMPIRIC_PCT / (ATTACK_TIME / 1000.0)
    t2 = hp / max(pdps - regen_hps - vamp_plate, 1)
    print(f"  {pdps:>11,} | {t0:>10.0f}s | {t1:>10.0f}s | {t2:>22.0f}s")

print()
print("=" * 74)
print("PROPOSED REBALANCE (make rank raise threat, not just HP)")
print("=" * 74)
cur_hp_ladder = [1.5, 2.0, 3.0, 4.5, 6.0]
new_hp_ladder = [1.4, 1.8, 2.4, 3.2, 4.2]
cur_dmg_ladder = [1.15, 1.30, 1.50, 1.70, 2.00]
new_dmg_ladder = [1.20, 1.45, 1.70, 2.00, 2.35]
print(f"  {'rank':>4} | {'HP now':>8} {'HP new':>8} | {'dmg x now':>9} {'dmg x new':>9} | {'DPS now':>8} {'DPS new':>8} | {'solo kill (2500 dps)':>20}")
for i in range(5):
    rank = i + 1
    hpn, hpw = CLS_BASE_HP * cur_hp_ladder[i], CLS_BASE_HP * new_hp_ladder[i]
    a = raw(1.0, cur_dmg_ladder[i])
    b = raw(1.0, new_dmg_ladder[i])
    an, bn = sum(a) / 2 / 2.0, sum(b) / 2 / 2.0
    print(f"  {rank:>4} | {hpn:>8,.0f} {hpw:>8,.0f} | {cur_dmg_ladder[i]:>9.2f} {new_dmg_ladder[i]:>9.2f} | {an:>8.0f} {bn:>8.0f} | {hpn/2500:>8.0f}s {hpw/2500:>9.0f}s")

print()
print("  rank-5 delta: HP {:.0f} -> {:.0f} ({:+.0f}%), DPS {:.0f} -> {:.0f} ({:+.0f}%)".format(
    CLS_BASE_HP * cur_hp_ladder[4], CLS_BASE_HP * new_hp_ladder[4],
    (new_hp_ladder[4] / cur_hp_ladder[4] - 1) * 100,
    raw(1.0, cur_dmg_ladder[4])[1] and (sum(raw(1.0, cur_dmg_ladder[4])) / 4),
    (sum(raw(1.0, new_dmg_ladder[4])) / 4),
    ((sum(raw(1.0, new_dmg_ladder[4])) / sum(raw(1.0, cur_dmg_ladder[4]))) - 1) * 100))
