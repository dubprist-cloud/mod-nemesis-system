#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""What a levelling player actually faces when meeting a nemesis (level 40 band)."""

# creature_classlevelstats.sql, class WARRIOR
# NOTE: for sub-WotLK levels basehp1/basehp2 are 1 and the core falls back to basehp0
# (ObjectMgr::LoadCreatureClassLevelStats "xinef" fallback), and damage_* are equal
# across expansions, so the template's `exp` does not change anything at these levels.
LEVELS = {
    35: dict(hp=1220, dmg=15.8617, ap=118),
    40: dict(hp=1524, dmg=18.2971, ap=136),
    45: dict(hp=1848, dmg=24.6797, ap=184),
}

ATTACK_TIME = 2000
BASE_ATTACK_TIME = 2000
CRIT = 0.05
CRIT_MULT = 2.0

HP_LADDER = [1.5, 2.0, 3.0, 4.5, 6.0]
DMG_LADDER = [1.15, 1.30, 1.50, 1.70, 2.00]
SAVAGE, ENRAGED = 1.25, 1.50
VAMPIRIC_PCT = 0.50
REGEN_PCT = 3.0
REGEN_INTERVAL_MS = 5000


def reduction(armor, attacker_level):
    lvl = attacker_level
    if lvl > 59:
        lvl = lvl + 4.5 * (lvl - 59)
    t = 0.1 * armor / (8.5 * lvl + 40)
    return min(t / (1 + t), 0.75)


def stats(level, rank, damage_modifier=1.0):
    s = LEVELS[level]
    dmult = DMG_LADDER[rank - 1]
    asm = ATTACK_TIME / 1000.0
    ap = s["ap"] / 14.0
    lo = (s["dmg"] * dmult + ap) * damage_modifier * asm
    hi = (s["dmg"] * 1.5 * dmult + ap) * damage_modifier * asm
    avg = (lo + hi) / 2
    dps = avg / (ATTACK_TIME / 1000.0) * (1 + CRIT * (CRIT_MULT - 1))
    hp = s["hp"] * HP_LADDER[rank - 1]
    return dict(hp=hp, lo=lo, hi=hi, avg=avg, dps=dps)


print("=" * 82)
print("A. THE SAME MOB, BEFORE AND AFTER BECOMING A NEMESIS (level 40, DamageModifier 1.0)")
print("=" * 82)
base = stats(40, 1)
plain = dict(hp=LEVELS[40]["hp"],
             lo=stats(40, 1)["lo"], hi=stats(40, 1)["hi"])
# recompute a plain (unpromoted) level-40 mob explicitly
ap40 = LEVELS[40]["ap"] / 14.0
p_lo = (LEVELS[40]["dmg"] + ap40) * 2.0
p_hi = (LEVELS[40]["dmg"] * 1.5 + ap40) * 2.0
print(f"  plain level-40 mob : HP {LEVELS[40]['hp']:>6,}  hit {p_lo:>6.1f}-{p_hi:>6.1f}  DPS {((p_lo+p_hi)/2/2.0):>5.1f}")
for r in range(1, 6):
    st = stats(40, r)
    print(f"  rank {r} nemesis   : HP {st['hp']:>6,.0f}  hit {st['lo']:>6.1f}-{st['hi']:>6.1f}  DPS {st['dps']:>5.1f}")

print()
print("=" * 82)
print("B. 'REQUIRED DPS TO SOLO' — how much damage a player must do to win the race")
print("   (player wins when nemesisHP / playerDPS < playerHP / nemesisDPS)")
print("=" * 82)
print(f"  {'rank':>4} | {'nem HP':>8} | {'nem DPS':>7} | {'vs 1200 HP':>11} | {'vs 1500 HP':>11} | {'vs 1900 HP':>11}")
for r in range(1, 6):
    st = stats(40, r)
    row = f"  {r:>4} | {st['hp']:>8,.0f} | {st['dps']:>7.1f} |"
    for php in (1200, 1500, 1900):
        req = st["hp"] * st["dps"] / php
        row += f" {req:>10.0f} |"
    print(row)
print()
print("  typical level-40 levelling DPS: ~90-130. Break-even is 270-430 -> unreachable solo.")

print()
print("=" * 82)
print("C. WALK-THROUGH: level-40 player (1600 HP, 2400 armour, 120 DPS) meets rank-5 nemesis")
print("=" * 82)
st = stats(40, 5)
red = reduction(2400, 40)
hit = st["avg"] * (1 - red)
dps_taken = hit / (ATTACK_TIME / 1000.0)
regen_hps = st["hp"] * REGEN_PCT / 100.0 / (REGEN_INTERVAL_MS / 1000.0)
vamp_hps = hit * VAMPIRIC_PCT / (ATTACK_TIME / 1000.0)
print(f"  armour reduction on the player : {red*100:.1f}%")
print(f"  damage taken per hit           : {hit:.0f}  ({dps_taken:.1f} DPS)")
print(f"  player dies in                 : {1600/dps_taken:.0f}s")
print(f"  nemesis dies in                : {st['hp']/120:.0f}s  (player DPS 120)")
print(f"  WITH Savage+Enraged            : {1600/(hit*SAVAGE*ENRAGED/2.0):.0f}s to kill the player")
print(f"  WITH Vampiric + Regenerating   : nemesis heals {regen_hps+vamp_hps:.0f} hps ->")
print(f"                                   effective player DPS {120-regen_hps-vamp_hps:.0f} -> {st['hp']/max(120-regen_hps-vamp_hps,1):.0f}s")
print(f"  worst single hit (max roll+crit+S+E): {st['hi']*(1-red)*SAVAGE*ENRAGED*CRIT_MULT:.0f} = {st['hi']*(1-red)*SAVAGE*ENRAGED*CRIT_MULT/1600*100:.0f}% of the player's HP")

print()
print("=" * 82)
print("D. WORST MATCHUP: level-40 player meets a nemesis made from a LEVEL-45 mob")
print("=" * 82)
for r in (1, 3, 5):
    st = stats(45, r)
    red = reduction(2400, 45)
    hit = st["avg"] * (1 - red)
    dps_taken = hit / (ATTACK_TIME / 1000.0)
    print(f"  rank {r}: HP {st['hp']:>6,.0f} | hit {hit:>5.0f} ({dps_taken:>5.1f} DPS) | kills a 1600 HP player in {1600/dps_taken:>4.0f}s"
          f" | player at 120 DPS needs {st['hp']/120:>4.0f}s")

print()
print("=" * 82)
print("E. FOR CONTRAST — the same rank ladder at level 80 (player 20 000 HP, 2 500 DPS)")
print("=" * 82)
L80 = dict(hp=12600, dmg=164.924, ap=642)
for r in range(1, 6):
    dmult = DMG_LADDER[r - 1]
    ap = L80["ap"] / 14.0
    lo = (L80["dmg"] * dmult + ap) * 2.0
    hi = (L80["dmg"] * 1.5 * dmult + ap) * 2.0
    dps = ((lo + hi) / 2 / 2.0) * (1 + CRIT * (CRIT_MULT - 1))
    hp = L80["hp"] * HP_LADDER[r - 1]
    req = hp * dps / 20000
    print(f"  rank {r}: HP {hp:>8,.0f} | DPS {dps:>6.0f} | required player DPS {req:>6.0f} | actual 2500 -> {'WIN' if 2500 > req else 'LOSE'}")

print()
print("=" * 82)
print("F. WHEN DOES A NEMESIS BECOME TRIVIAL? (rank 5, player DPS 120, needs < his own HP/nemDPS)")
print("=" * 82)
for lvl in (35, 40, 45):
    st = stats(lvl, 5)
    print(f"  level-{lvl} nemesis: HP {st['hp']:>6,.0f}, DPS {st['dps']:>5.1f} -> a level-40 player at 120 DPS needs {st['hp']/120:>4.0f}s "
          f"and survives {1600/st['dps']:>4.0f}s  -> {'LOSE' if st['hp']/120 > 1600/st['dps'] else 'WIN'}")
