#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Rank-5 nemesis damage simulation for a level-80 mob.

Every constant below is taken from the AzerothCore source tree or from
data/sql/base/db_world/creature_classlevelstats.sql (level 80, class WARRIOR).
"""

# ---------------------------------------------------------------- core data
BASE_MINDAMAGE = 1.0        # Unit.h
BASE_MAXDAMAGE = 2.0        # Unit.h
BASE_ATTACK_TIME = 2000     # Unit.h

# creature_classlevelstats.sql, level 80, class 1 (WARRIOR)
CLS_BASE_HP = 12600         # basehp2  (WotLK)
CLS_BASE_DAMAGE = 164.924   # damage_exp2 (WotLK)
CLS_ATTACK_POWER = 642

TEMPLATE_BASE_VARIANCE = 1.0    # creature_template.BaseVariance default
TEMPLATE_ATTACK_TIME = 2000     # creature_template.BaseAttackTime (typical)

# ------------------------------------------------- module (rank 5) multipliers
DAMAGE_MULT = 2.00          # GetDamageMultiplier(5)
HEALTH_MULT = 6.00          # GetHealthMultiplier(5)
SCALE_MULT = 1.60           # GetScaleMultiplier(5)

# affix multipliers from OnDamage
SAVAGE = 1.25               # GetSavageDamageMultiplier()
ENRAGED = 1.50              # NemesisSystem.EnragedDamageMultiplier default
AFFIX_CAP = 2.50            # NemesisSystem.MaxAffixDamageMultiplier default
ENRAGE_HP_THRESHOLD = 30.0  # NemesisSystem.EnragedHealthPctThreshold default

VAMPIRIC_HEAL_PCT = 0.50    # GetVampiricHealPct()
SWIFT_SPEED = 1.50          # GetSwiftSpeedMultiplier()
SWIFT_ATTACK_MULT = 0.70    # GetSwiftAttackTimeMultiplier()

CREATURE_CRIT = 5.0         # Unit::GetUnitCriticalChance -> creatures
CRIT_MULT = 2.0

# ------------------------------------------------------------------ helpers
weapon_min = max(BASE_MINDAMAGE, CLS_BASE_DAMAGE)
weapon_max = max(BASE_MAXDAMAGE, CLS_BASE_DAMAGE * 1.5)
ap_term = CLS_ATTACK_POWER / 14.0 * TEMPLATE_BASE_VARIANCE


def raw_damage(damage_modifier, attack_time_ms):
    """Pre-armor melee range for a rank-5 nemesis (Unit::CalculateMinMaxDamage)."""
    asm = attack_time_ms / 1000.0
    wmin = weapon_min * DAMAGE_MULT
    wmax = weapon_max * DAMAGE_MULT
    lo = (wmin + ap_term) * damage_modifier * asm
    hi = (wmax + ap_term) * damage_modifier * asm
    return lo, hi


def armor_reduction(armor, attacker_level=80):
    """Unit::CalcArmorReducedDamage."""
    lvl = attacker_level
    if lvl > 59:
        lvl = lvl + 4.5 * (lvl - 59)
    tmp = 0.1 * armor / (8.5 * lvl + 40)
    tmp = tmp / (1.0 + tmp)
    return min(max(tmp, 0.0), 0.75)


print("=" * 78)
print("A. INPUTS  (level 80 mob, class WARRIOR, creature_classlevelstats)")
print("=" * 78)
print(f"  base weapon damage (WotLK) : {CLS_BASE_DAMAGE:.3f} .. {CLS_BASE_DAMAGE*1.5:.3f}")
print(f"  attack power               : {CLS_ATTACK_POWER}  -> AP term /14 = {ap_term:.3f}")
print(f"  base health (WotLK)        : {CLS_BASE_HP}")
print(f"  base attack time           : {TEMPLATE_ATTACK_TIME} ms")
print(f"  module rank-5 multipliers  : damage x{DAMAGE_MULT}, health x{HEALTH_MULT}, scale x{SCALE_MULT}")
print(f"  after rank-5 weapon range  : {weapon_min*DAMAGE_MULT:.3f} .. {weapon_max*DAMAGE_MULT:.3f}")
print()
print(f"  health after rank-5 (HealthModifier=1.0) : {CLS_BASE_HP*HEALTH_MULT:,.0f}")
print(f"  health after rank-5 (HealthModifier=2.0) : {CLS_BASE_HP*2*HEALTH_MULT:,.0f}")

print()
print("=" * 78)
print("B. RAW MELEE PER HIT (before armor), DamageModifier variants")
print("=" * 78)
print(f"  {'DamageModifier':>14} | {'no Swift (2.0s)':>26} | {'Swift (1.4s)':>26}")
print(f"  {'':>14} | {'min':>8} {'max':>8} {'avg':>7} | {'min':>8} {'max':>8} {'avg':>7}")
for dm in (1.0, 1.5, 2.0, 3.0):
    a = raw_damage(dm, TEMPLATE_ATTACK_TIME)
    b = raw_damage(dm, TEMPLATE_ATTACK_TIME * SWIFT_ATTACK_MULT)
    print(f"  {dm:>14.2f} | {a[0]:>8.1f} {a[1]:>8.1f} {sum(a)/2:>7.1f} | {b[0]:>8.1f} {b[1]:>8.1f} {sum(b)/2:>7.1f}")

print()
print("=" * 78)
print("C. AFFIX MULTIPLIER DISTRIBUTION AT RANK 5  (3 of 7 affixes, uniform)")
print("=" * 78)
import math
combos = math.comb(7, 3)
rows = [
    ("Savage + Enraged", math.comb(5, 1), SAVAGE * ENRAGED),
    ("Savage only",      math.comb(5, 2), SAVAGE),
    ("Enraged only",     math.comb(5, 2), ENRAGED),
    ("neither",          math.comb(5, 3), 1.0),
]
print(f"  {'roll':>17} | {'p':>7} | {'x at HP>30%':>11} | {'x at HP<=30%':>12}")
for name, cnt, mult in rows:
    p = cnt / combos
    active = min(mult, AFFIX_CAP) if name != "Enraged only" else 1.0
    enraged_on = min(mult if "Enraged" in name else (SAVAGE if "Savage" in name else 1.0), AFFIX_CAP)
    print(f"  {name:>17} | {p*100:>6.2f}% | {active:>11.3f} | {enraged_on:>12.3f}")
print(f"  (cap is {AFFIX_CAP}; highest achievable product is {SAVAGE*ENRAGED:.3f} -> cap never binds today)")

print()
print("=" * 78)
print("D. FINAL DAMAGE AFTER ARMOR + AFFIX  (DamageModifier = 1.0, no Swift)")
print("=" * 78)
lo, hi = raw_damage(1.0, TEMPLATE_ATTACK_TIME)
avg = (lo + hi) / 2
print(f"  raw range {lo:.1f} .. {hi:.1f}   (avg {avg:.1f})")
print()
print(f"  {'target armor':>13} | {'reduction':>9} | {'post-armor avg':>14} | {'+Savage+Enraged avg':>20} | {'max crit (S+E)':>14}")
for armor in (2500, 5000, 9000, 14000, 20000):
    red = armor_reduction(armor)
    post = avg * (1 - red)
    se = post * min(SAVAGE * ENRAGED, AFFIX_CAP)
    crit = hi * (1 - red) * min(SAVAGE * ENRAGED, AFFIX_CAP) * CRIT_MULT
    print(f"  {armor:>13,} | {red*100:>8.1f}% | {post:>14.0f} | {se:>20.0f} | {crit:>14.0f}")

print()
print("=" * 78)
print("E. DPS AND SUSTAIN  (DamageModifier = 1.0)")
print("=" * 78)
for label, at in (("no Swift", TEMPLATE_ATTACK_TIME), ("Swift", TEMPLATE_ATTACK_TIME * SWIFT_ATTACK_MULT)):
    l, h = raw_damage(1.0, at)
    a = (l + h) / 2
    dps = a / (at / 1000.0)
    dps_crit = dps * (1 + CREATURE_CRIT / 100.0 * (CRIT_MULT - 1))
    print(f"  {label:>9}: avg hit {a:>7.1f}, interval {at/1000.0:.2f}s -> DPS {dps:>7.1f} (with crits {dps_crit:>7.1f})")

print()
print("  Enraged active (HP<=30%):")
for label, at in (("no Swift", TEMPLATE_ATTACK_TIME), ("Swift", TEMPLATE_ATTACK_TIME * SWIFT_ATTACK_MULT)):
    l, h = raw_damage(1.0, at)
    a = (l + h) / 2 * ENRAGED
    dps = a / (at / 1000.0)
    print(f"  {label:>9}: avg hit {a:>7.1f} -> DPS {dps:>7.1f}")

print()
print("  Savage + Enraged active:")
for label, at in (("no Swift", TEMPLATE_ATTACK_TIME), ("Swift", TEMPLATE_ATTACK_TIME * SWIFT_ATTACK_MULT)):
    l, h = raw_damage(1.0, at)
    a = (l + h) / 2 * SAVAGE * ENRAGED
    dps = a / (at / 1000.0)
    print(f"  {label:>9}: avg hit {a:>7.1f} -> DPS {dps:>7.1f}")

print()
print("=" * 78)
print("F. TIME TO KILL A LEVEL-80 PLAYER (DamageModifier = 1.0, avg roll)")
print("=" * 78)
for hp_label, php in (("caster ~16k", 16000), ("dps ~20k", 20000), ("tank ~30k", 30000)):
    line = f"  {hp_label:>12} |"
    for armor_label, armor in (("cloth 2.5k", 2500), ("mail 9k", 9000), ("plate 14k", 14000)):
        l, h = raw_damage(1.0, TEMPLATE_ATTACK_TIME)
        post = (l + h) / 2 * (1 - armor_reduction(armor))
        line += f" {armor_label}: {php/post:>5.1f}s |"
    print(line)

print()
print("=" * 78)
print("G. VAMPIRIC SUSTAIN (heals 50% of damage dealt, before the player's mitigation)")
print("=" * 78)
l, h = raw_damage(1.0, TEMPLATE_ATTACK_TIME)
print(f"  heal per hit: {l*VAMPIRIC_HEAL_PCT:>7.0f} .. {h*VAMPIRIC_HEAL_PCT:>7.0f}  (avg {(l+h)/2*VAMPIRIC_HEAL_PCT:>7.0f})")
print(f"  heal per second: {(l+h)/2*VAMPIRIC_HEAL_PCT/(TEMPLATE_ATTACK_TIME/1000.0):>7.0f} hps vs a pool of {CLS_BASE_HP*HEALTH_MULT:,.0f}")


def base_mob(damage_modifier, attack_time_ms):
    """Same creature BEFORE promotion, for comparison."""
    asm = attack_time_ms / 1000.0
    lo = (weapon_min + ap_term) * damage_modifier * asm
    hi = (weapon_max + ap_term) * damage_modifier * asm
    return lo, hi


print()
print("=" * 78)
print("H. EFFECTIVE GAIN vs THE SAME MOB BEFORE PROMOTION (DamageModifier = 1.0)")
print("=" * 78)
b = base_mob(1.0, TEMPLATE_ATTACK_TIME)
n = raw_damage(1.0, TEMPLATE_ATTACK_TIME)
print(f"  plain mob      : {b[0]:>7.1f} .. {b[1]:>7.1f}   avg {sum(b)/2:>7.1f}   DPS {sum(b)/2/2.0:>7.1f}")
print(f"  rank-5 nemesis : {n[0]:>7.1f} .. {n[1]:>7.1f}   avg {sum(n)/2:>7.1f}   DPS {sum(n)/2/2.0:>7.1f}")
print(f"  -> effective multiplier {sum(n)/sum(b):.3f}x  (nominal is {DAMAGE_MULT:.2f}x; the flat AP term is not scaled)")
print(f"  -> health {CLS_BASE_HP:,} -> {CLS_BASE_HP*HEALTH_MULT:,}  ({HEALTH_MULT:.0f}x), model scale x{SCALE_MULT}")

print()
print("=" * 78)
print("I. WORST CASE SINGLE HIT (max roll + crit + Savage + Enraged, no armor)")
print("=" * 78)
print(f"  {'DamageModifier':>14} | {'raw max hit':>12} | {'x1.875 (S+E)':>13} | {'+crit x2':>10}")
for dm in (1.0, 1.5, 2.0, 3.0):
    hi = raw_damage(dm, TEMPLATE_ATTACK_TIME)[1]
    se = hi * SAVAGE * ENRAGED
    print(f"  {dm:>14.2f} | {hi:>12.0f} | {se:>13.0f} | {se*CRIT_MULT:>10.0f}")
print("  (no armor reduction applied - this is what lands on a target with 0 armor)")

print()
print("=" * 78)
print("J. EXPECTED AFFIX MULTIPLIER (probability weighted, both HP bands)")
print("=" * 78)
p_both, p_sav, p_enr, p_none = 5/35, 10/35, 10/35, 10/35
above = p_both*SAVAGE + p_sav*SAVAGE + p_enr*1.0 + p_none*1.0
below = p_both*SAVAGE*ENRAGED + p_sav*SAVAGE + p_enr*ENRAGED + p_none*1.0
print(f"  while HP >  30% : {above:.3f}x")
print(f"  while HP <= 30% : {below:.3f}x")
print(f"  overall (nemesis spends ~70% of the fight above the threshold): {0.7*above + 0.3*below:.3f}x")
