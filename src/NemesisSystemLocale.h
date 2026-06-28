#pragma once

#include "SharedDefines.h"
#include <array>
#include <string_view>

enum class NemesisStringId : uint32
{
    // GM command responses
    CMD_NEED_PLAYER_BOOTSTRAP,
    CMD_NEED_PLAYER_REPORT,
    CMD_NEED_PLAYER_SYNC,
    CMD_SELECT_CREATURE,
    CMD_DEBUG_HEADER,
    CMD_NOT_A_NEMESIS,
    CMD_DEBUG_RANK,
    CMD_DEBUG_HEALTH,
    CMD_DEBUG_DAMAGE,
    CMD_DEBUG_COOLDOWN,
    CMD_INFO_NOT_NEMESIS,
    CMD_INFO_HEADER,
    CMD_INFO_RANK,
    CMD_INFO_COOLDOWN,
    CMD_INFO_LOADED,
    CMD_INFO_NOT_LOADED,
    CMD_MARK_NEED_BOTH,
    CMD_MARK_DONE,
    CMD_CLEAR_SELECT,
    CMD_CLEAR_NOT_NEMESIS,
    CMD_CLEAR_DONE,
    CMD_REROLL_SELECT,
    CMD_REROLL_NOT_NEMESIS,
    CMD_REROLL_DONE,
    CMD_LIST_NEED_PLAYER,
    CMD_LIST_NO_MAP,
    CMD_LIST_HEADER,
    CMD_LIST_ENTRY,
    CMD_LIST_TEMP_ENTRY,
    CMD_LIST_NONE,
    CMD_LIST_TOTAL,
    CMD_MAPCLEAR_NEED_PLAYER,
    CMD_MAPCLEAR_NO_MAP,
    CMD_MAPCLEAR_NONE,
    CMD_MAPCLEAR_DONE,
    CMD_CLEARALL_DONE,
    CMD_RELOAD_FAIL,
    CMD_RELOAD_DONE,

    // Affix names
    AFFIX_VAMPIRIC,
    AFFIX_SWIFT,
    AFFIX_JUGGERNAUT,
    AFFIX_SAVAGE,
    AFFIX_SPELLWARD,
    AFFIX_ENRAGED,
    AFFIX_REGEN,
    AFFIX_NONE,

    // Announcement templates
    ANNOUNCE_RANK_UP,
    ANNOUNCE_CREATED,
    ANNOUNCE_REVENGE,
    ANNOUNCE_BOUNTY,

    COUNT
};

inline std::string_view GetNemesisString(LocaleConstant locale, NemesisStringId id)
{
    static std::array const enUs
    {
        /* CMD_NEED_PLAYER_BOOTSTRAP */  "You must be logged in as a player to request addon bootstrap data.",
        /* CMD_NEED_PLAYER_REPORT */     "You must be logged in as a player to report addon sightings.",
        /* CMD_NEED_PLAYER_SYNC */       "You must be logged in as a player to sync addon data.",
        /* CMD_SELECT_CREATURE */        "You must select a creature.",
        /* CMD_DEBUG_HEADER */           "Nemesis target: {} (entry {}, spawn {}, map {})",
        /* CMD_NOT_A_NEMESIS */          "Selected creature is not an active nemesis.",
        /* CMD_DEBUG_RANK */             "Rank {} | Affixes {} | TargetGuid {}",
        /* CMD_DEBUG_HEALTH */           "Health {} / {} | Scale {}",
        /* CMD_DEBUG_DAMAGE */           "Main damage {} - {}",
        /* CMD_DEBUG_COOLDOWN */         "Rank-up cooldown remaining {}s | Same victim cooldown remaining {}s",
        /* CMD_INFO_NOT_NEMESIS */       "Spawn {} is not an active nemesis.",
        /* CMD_INFO_HEADER */            "Spawn {} | {} | Entry {} | Map {}",
        /* CMD_INFO_RANK */              "Rank {} | Affixes {} | Target {}",
        /* CMD_INFO_COOLDOWN */          "Rank-up cooldown remaining {}s | Same victim cooldown remaining {}s",
        /* CMD_INFO_LOADED */            "Loaded now | HP {}/{} | Scale {}",
        /* CMD_INFO_NOT_LOADED */        "Not currently loaded on your map.",
        /* CMD_MARK_NEED_BOTH */         "You must select a creature while logged in as a player.",
        /* CMD_MARK_DONE */              "Marked {} as nemesis rank {} with affixes {}.",
        /* CMD_CLEAR_SELECT */           "You must select a creature.",
        /* CMD_CLEAR_NOT_NEMESIS */      "Selected creature is not an active nemesis.",
        /* CMD_CLEAR_DONE */             "Cleared nemesis state from {}.",
        /* CMD_REROLL_SELECT */          "You must select a creature.",
        /* CMD_REROLL_NOT_NEMESIS */     "Selected creature is not an active nemesis.",
        /* CMD_REROLL_DONE */            "Rerolled affixes for {}: {}.",
        /* CMD_LIST_NEED_PLAYER */       "You must be logged in as a player to list map nemeses.",
        /* CMD_LIST_NO_MAP */            "Unable to resolve your current map.",
        /* CMD_LIST_HEADER */            "Active nemeses on map {}:",
        /* CMD_LIST_ENTRY */             "Spawn {} | {} | Rank {} | Affixes {} | Target {}{}",
        /* CMD_LIST_TEMP_ENTRY */        "Temporary {} | {} | Rank {} | Affixes {} | Target {} | HP {}/{}",
        /* CMD_LIST_NONE */              "No active nemeses found on this map.",
        /* CMD_LIST_TOTAL */             "Total active nemeses on this map: {}.",
        /* CMD_MAPCLEAR_NEED_PLAYER */   "You must be logged in as a player to clear map nemeses.",
        /* CMD_MAPCLEAR_NO_MAP */        "Unable to resolve your current map.",
        /* CMD_MAPCLEAR_NONE */          "No active nemeses found on this map.",
        /* CMD_MAPCLEAR_DONE */          "Cleared {} active nemesis record(s) from map {}.",
        /* CMD_CLEARALL_DONE */          "Cleared all stored nemesis records.",
        /* CMD_RELOAD_FAIL */            "Nemesis System configuration reload failed.",
        /* CMD_RELOAD_DONE */            "Nemesis System configuration reloaded.",

        /* AFFIX_VAMPIRIC */             "Vampiric",
        /* AFFIX_SWIFT */                "Swift",
        /* AFFIX_JUGGERNAUT */           "Juggernaut",
        /* AFFIX_SAVAGE */               "Savage",
        /* AFFIX_SPELLWARD */            "Spellward",
        /* AFFIX_ENRAGED */              "Enraged",
        /* AFFIX_REGEN */                "Regenerating",
        /* AFFIX_NONE */                 "None",

        /* ANNOUNCE_RANK_UP */           "[Nemesis]: {} has reached rank {} at ({}). Affixes: {}.",
        /* ANNOUNCE_CREATED */           "[Nemesis]: {} has become a nemesis after slaying {} at ({}). Affixes: {}.",
        /* ANNOUNCE_REVENGE */           "[Nemesis]: {} claimed revenge on {} at rank {} near ({}).",
        /* ANNOUNCE_BOUNTY */            "[Nemesis]: {} claimed the bounty on {} at rank {} near ({}).",
    };

    static std::array const ruRu
    {
        /* CMD_NEED_PLAYER_BOOTSTRAP */  "Вы должны войти в игру как игрок, чтобы запросить данные аддона.",
        /* CMD_NEED_PLAYER_REPORT */     "Вы должны войти в игру как игрок, чтобы отправить сообщение аддона.",
        /* CMD_NEED_PLAYER_SYNC */       "Вы должны войти в игру как игрок, чтобы синхронизировать аддон.",
        /* CMD_SELECT_CREATURE */        "Вы должны выбрать существо.",
        /* CMD_DEBUG_HEADER */           "Цель немизиды: {} (entry {}, spawn {}, map {})",
        /* CMD_NOT_A_NEMESIS */          "Выбранное существо не является активной немизидой.",
        /* CMD_DEBUG_RANK */             "Ранг {} | Аффиксы {} | Цель GUID {}",
        /* CMD_DEBUG_HEALTH */           "Здоровье {} / {} | Масштаб {}",
        /* CMD_DEBUG_DAMAGE */           "Основной урон {} - {}",
        /* CMD_DEBUG_COOLDOWN */         "Кулдаун повышения ранга {}с | Кулдаун той же жертвы {}с",
        /* CMD_INFO_NOT_NEMESIS */       "Спавн {} не является активной немизидой.",
        /* CMD_INFO_HEADER */            "Спавн {} | {} | Entry {} | Map {}",
        /* CMD_INFO_RANK */              "Ранг {} | Аффиксы {} | Цель {}",
        /* CMD_INFO_COOLDOWN */          "Кулдаун повышения ранга {}с | Кулдаун той же жертвы {}с",
        /* CMD_INFO_LOADED */            "Загружен сейчас | HP {}/{} | Масштаб {}",
        /* CMD_INFO_NOT_LOADED */        "Не загружен на вашей карте.",
        /* CMD_MARK_NEED_BOTH */         "Вы должны выбрать существо, будучи в игре как игрок.",
        /* CMD_MARK_DONE */              "Немизида {} помечена рангом {} с аффиксами {}.",
        /* CMD_CLEAR_SELECT */           "Вы должны выбрать существо.",
        /* CMD_CLEAR_NOT_NEMESIS */      "Выбранное существо не является активной немизидой.",
        /* CMD_CLEAR_DONE */             "Состояние немизиды сброшено для {}.",
        /* CMD_REROLL_SELECT */          "Вы должны выбрать существо.",
        /* CMD_REROLL_NOT_NEMESIS */     "Выбранное существо не является активной немизидой.",
        /* CMD_REROLL_DONE */            "Аффиксы переброшены для {}: {}.",
        /* CMD_LIST_NEED_PLAYER */       "Вы должны войти в игру как игрок, чтобы увидеть список немизид.",
        /* CMD_LIST_NO_MAP */            "Не удалось определить вашу текущую карту.",
        /* CMD_LIST_HEADER */            "Активные немизиды на карте {}:",
        /* CMD_LIST_ENTRY */             "Спавн {} | {} | Ранг {} | Аффиксы {} | Цель {}{}",
        /* CMD_LIST_TEMP_ENTRY */        "Временная {} | {} | Ранг {} | Аффиксы {} | Цель {} | HP {}/{}",
        /* CMD_LIST_NONE */              "На этой карте не найдено активных немизид.",
        /* CMD_LIST_TOTAL */             "Всего активных немизид на этой карте: {}.",
        /* CMD_MAPCLEAR_NEED_PLAYER */   "Вы должны войти в игру как игрок, чтобы очистить немизид на карте.",
        /* CMD_MAPCLEAR_NO_MAP */        "Не удалось определить вашу текущую карту.",
        /* CMD_MAPCLEAR_NONE */          "На этой карте не найдено активных немизид.",
        /* CMD_MAPCLEAR_DONE */          "Очищено {} записей немизид на карте {}.",
        /* CMD_CLEARALL_DONE */          "Все записи немизид удалены.",
        /* CMD_RELOAD_FAIL */            "Не удалось перезагрузить конфигурацию Nemesis System.",
        /* CMD_RELOAD_DONE */            "Конфигурация Nemesis System перезагружена.",

        /* AFFIX_VAMPIRIC */             "Вампирический",
        /* AFFIX_SWIFT */                "Стремительный",
        /* AFFIX_JUGGERNAUT */           "Несокрушимый",
        /* AFFIX_SAVAGE */               "Свирепый",
        /* AFFIX_SPELLWARD */            "Антимагия",
        /* AFFIX_ENRAGED */              "Разъярённый",
        /* AFFIX_REGEN */                "Регенерирующий",
        /* AFFIX_NONE */                 "Нет",

        /* ANNOUNCE_RANK_UP */           "[Немизида]: {} достиг(ла) ранга {} в ({}). Аффиксы: {}.",
        /* ANNOUNCE_CREATED */           "[Немизида]: {} стал(а) немизидой, убив {} в ({}). Аффиксы: {}.",
        /* ANNOUNCE_REVENGE */           "[Немизида]: {} отомстил(а) {} (ранг {}) у ({}).",
        /* ANNOUNCE_BOUNTY */            "[Немизида]: {} получил(а) награду за {} (ранг {}) у ({}).",
    };

    static_assert(enUs.size() == size_t(NemesisStringId::COUNT));
    static_assert(ruRu.size() == size_t(NemesisStringId::COUNT));

    size_t const index = size_t(id);
    if (index >= size_t(NemesisStringId::COUNT))
        return {}; // silence warning, should never happen

    switch (locale)
    {
        case LOCALE_ruRU:
            return ruRu[index];
        default:
            return enUs[index];
    }
}
