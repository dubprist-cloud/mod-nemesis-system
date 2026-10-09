local L = LibStub("AceLocale-3.0"):NewLocale("NemesisTracker", "ruRU")
if not L then return end

-- Filter buttons
L["All"] = "Все"
L["Own"] = "Свои"
L["Party"] = "Группа"
L["Guild"] = "Гильдия"
L["Public"] = "Всеобщие"

-- Scope buttons
L["All Zones"] = "Все зоны"
L["This Map"] = "Эта карта"

-- Button labels
L["Refresh"] = "Обновить"
L["Waypoint"] = "Путевая точка"
L["Select Zone"] = "Выбрать зону"
L["Select zone"] = "Выбрать зону"

-- Minimap button / window title
L["N"] = "N"
L["Nemesis Tracker"] = "Nemesis Tracker"
L["Left-click to toggle"] = "ЛКМ — открыть/закрыть"
L["Drag to move"] = "Перетащите для перемещения"

-- Zone menu
L["No zones available"] = "Нет доступных зон"

-- Map display
L["Map data unavailable"] = "Данные карты недоступны"
L["No zone selected"] = "Зона не выбрана"

-- Zoom / creature count
L["1 creature"] = "1 существо"
L["%d creatures"] = "%d существ"

-- Format strings
L["%ds ago"] = "%d с назад"
L["%dm ago"] = "%d мин назад"
L["%dh ago"] = "%d ч назад"
L["R%d"] = "Р%d"
L["Page %d/%d"] = "Стр. %d/%d"
L["Page 1/1"] = "Стр. 1/1"

-- Status bar
L["State: %s  Filter: %s  Scope: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"] = "Состояние: %s  Фильтр: %s  Охват: %s  Отслеж.: %d  Стр.: %d/%d  Зона: %s  Синхр.: %s"
L["State: %s  Filter: %s  Scope: %s  Search: %s  Tracked: %d  Page: %d/%d  Zone: %s  Last Sync: %s"] = "Состояние: %s  Фильтр: %s  Охват: %s  Поиск: %s  Отслеж.: %d  Стр.: %d/%d  Зона: %s  Синхр.: %s"

-- Waypoint chat message
L["Nemesis waypoint: %s - %s (%.1f, %.1f, %.1f)"] = "Немезида: %s — %s (%.1f, %.1f, %.1f)"

-- Tooltip lines
L["Level %d  Rank %d - %s"] = "Ур. %d  Ранг %d — %s"
L["Last Seen: "] = "Последний раз: "
L["Reward: "] = "Награда: "
L["Threat: "] = "Угроза: "
L["MapX/Y: %.3f, %.3f"] = "Карта X/Y: %.3f, %.3f"
L["Relation: %s"] = "Отношение: %s"
L["Reward: %s  Threat: %s"] = "Награда: %s  Угроза: %s"
L["Zone: %s"] = "Зона: %s"
L["Status: %s  Source: %s"] = "Статус: %s  Источник: %s"

-- Fallback display values
L["Unknown"] = "Неизвестно"
L["Nemesis"] = "Немезида"
L["Marked"] = "Отмечен"
L["none"] = "нет"
L["low"] = "низкая"
L["medium"] = "средняя"
L["high"] = "высокая"
L["extreme"] = "экстремальная"
L["public"] = "общее"
L["unknown"] = "неизвестно"
L["fresh"] = "свежий"
L["fading"] = "устаревает"
L["stale"] = "устарел"
L["hidden"] = "скрыт"
L["idle"] = "ожидание"
L["connected"] = "подключено"
L["requesting"] = "запрос"
L["bootstrap"] = "загрузка"
L["live"] = "активно"
L["never"] = "никогда"
L["None"] = "Нет"
L["all"] = "все"
L["own"] = "свои"
L["party"] = "группа"
L["guild"] = "гильдия"
L["zone"] = "зона"
-- Source values
L["peer-sync"] = "пир-синх"
L["local-cache"] = "лок. кэш"
L["server-bootstrap"] = "загрузка"
L["rank5-broadcast"] = "ранг5"
L["server-validated"] = "сервер"

L["Previous zone: %s"] = "Предыдущая зона: %s"
L["Next zone: %s"] = "Следующая зона: %s"

-- Leaderboard
L["Top"] = "Топ"
L["Map"] = "Карта"
L["Top killers this month"] = "Лучшие охотники месяца"
L["Place  Character  Kills / Revenge / Bounty / Best"] = "Место  Персонаж  Убийств / Месть / Награда / Лучший"
L["No kills recorded this month."] = "В этом месяце убийств не зафиксировано."
L["No kills yet this month"] = "В этом месяце убийств пока нет"
L["Waypoint set: %s"] = "Путевая точка: %s"
L["Affixes: %s"] = "Аффиксы: %s"

-- Affix descriptions (mirror the module's default configuration)
L["AFFIX_DESC_VAMPIRIC"] = "Вампиризм: лечится на 25% нанесённого урона."
L["AFFIX_DESC_SWIFT"] = "Стремительность: атакует на 30% чаще, урон +25%, бег +50%."
L["AFFIX_DESC_JUGGERNAUT"] = "Несокрушимость: иммунитет к замедлению, руту, страху, стану, очарованию, сну, полиморфу и отбрасыванию."
L["AFFIX_DESC_SAVAGE"] = "Свирепость: урон +25%."
L["AFFIX_DESC_SPELLWARD"] = "Антимагия: получаемый магический урон -30%."
L["AFFIX_DESC_ENRAGED"] = "Ярость: урон +50% при здоровье ниже 30%."
L["AFFIX_DESC_REGEN"] = "Регенерация: восстанавливает 3% здоровья каждые 5 секунд."
