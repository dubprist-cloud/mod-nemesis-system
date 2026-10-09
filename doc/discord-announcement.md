# Пост для Discord — анонс «Системы Немизид»

**Иллюстрация:** `doc/assets/nemesis-discord-banner.png` (1600×900) — прикрепить к посту как изображение.
Пересобрать баннер: `python .workbuddy-ai/tools/make_discord_banner.py doc/assets/nemesis-discord-banner.png`

Ниже — готовый текст. Русская версия основная, английская — короткая, на случай если в канале есть
англоязычные игроки.

---

## Текст поста (RU)

**⚔️ СИСТЕМА НЕМИЗИД**

*Убей — или стань добычей.*

Когда существо в открытом мире убивает игрока, оно становится **Немизидой**. Навсегда. Оно растёт в ранге, обзаводится аффиксами и начинает охотиться на всех подряд.

**▸ 5 рангов.** От `Marked` до `Mythic`: с каждым рангом Немизида крупнее, злее и живучее. Появление Немизиды 5 ранга объявляется на весь сервер.

**▸ 7 аффиксов.** Вампиризм, Стремительность, Несокрушимость, Свирепость, Антимагия, Ярость, Регенерация. Набор случаен, и у высоких рангов аффиксов больше — именно они решают, будет бой лёгким или безнадёжным.

**▸ Месть.** Убил свою Немизиду — забрал награду за месть. Убил чужую — забрал награду за голову. Месть принадлежит **каждому**, кого она успела убить, а не только последней жертве.

**▸ Трекер в игре.** Аддон **NemesisTracker** показывает Немизид на карте мира и на миникарте, ведёт к ним путевой точкой и раскрывает их аффиксы в подсказке. Больше не нужно выяснять в чате, кто и где тебя убил.

**▸ Топ охотников месяца.** Лучшие убийцы месяца — прямо в аддоне. Своё место видно, даже если в десятку не попал.

*Немизида живёт, пока растёт: шесть часов без убийств — и она исчезает. Охота идёт в обе стороны.*

`.nemesis` — команды в игре · аддон — в `Interface/AddOns/NemesisTracker`

---

## English (short)

**⚔️ NEMESIS SYSTEM**

*Kill — or be hunted.*

When a creature kills a player in the open world it becomes a **Nemesis**. Permanently. It climbs five ranks from `Marked` to `Mythic`, rolls up to seven affixes, and goes after everyone.

**Revenge** belongs to every player it has killed. **Bounty** goes to whoever kills it. The **NemesisTracker** addon plots nemeses on the world map and minimap, hands off waypoints, and explains their affixes in the tooltip. A **monthly leaderboard** sits in the addon itself — your own standing shows up even when you are outside the top ten.

A Nemesis lives only while it grows: six hours without a kill and it fades. The hunt runs both ways.

`.nemesis` for commands · addon in `Interface/AddOns/NemesisTracker`

---

## Заметки

- «Шесть часов» — это значение `NemesisSystem.DecayHours` на **этом** сервере (в `.dist` по умолчанию 48).
  Если поменяешь настройку — поправь текст поста.
- Названия рангов (`Marked`, `Hated`, `Relentless`, `Legendary`, `Mythic`) намеренно оставлены
  латиницей: сервер пишет их в имя существа через `SetName`, поэтому локализовать их по-игроку
  структурно нельзя. В посте они совпадают с тем, что игрок увидит в игре.
- Короткая версия для закрепа в канале: только первый абзац и три пункта из пяти
  (ранги, трекер, топ).
