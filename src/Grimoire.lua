local Grimoire = {
    ['IMP'] = { 
        name = 'Imp', 
        cost = 10, 
        color = {1, 0, 0.3, 1}, 
        width = 24, 
        height = 24, 
        speed = 20, 
        type = 'summon', 
        attackRange = 120,
        description = "A swift ranged demon that hurls fireballs from afar. Imps are cheap and fast, making them ideal for overwhelming enemies with numbers. Their long range allows them to strike before heroes can retaliate."
    },
    ['VOIDWALKER'] = { 
        name = 'Voidwalker', 
        cost = 30, 
        color = {0.1, 0.1, 0.6, 1}, 
        width = 24, 
        height = 24, 
        speed = 10, 
        type = 'summon', 
        attackRange = 10,
        description = "A hulking melee brute from the void. Slow but devastating in close combat. Voidwalkers excel at holding the line and crushing enemies that dare approach. Their short range means they must close the gap first."
    },
    
    -- Upgrades
    ['MANA'] = { 
        name = 'Mana Boost', 
        cost = 50, 
        type = 'upgrade', 
        color = {0.2, 0.4, 0.8, 1}, 
        effect = 'max_mana', 
        amount = 10,
        description = "Expand your mana pool, allowing you to summon more demons before needing to regenerate. Each purchase increases your maximum mana by 10 points."
    },
    ['REGEN'] = { 
        name = 'Regen Boost', 
        cost = 100, 
        type = 'upgrade', 
        color = {0.2, 0.8, 0.4, 1}, 
        effect = 'regen', 
        amount = 1,
        description = "Accelerate your mana regeneration rate. The faster you regenerate, the more demons you can field. Essential for maintaining constant pressure on the heroes."
    },
    ['HEAL'] = { 
        name = 'Heal Castle', 
        cost = 200, 
        type = 'upgrade', 
        color = {1, 0.2, 0.2, 1}, 
        effect = 'heal', 
        amount = 1,
        description = "Restore one heart to your castle. Use this when heroes have broken through your defenses. A costly but vital lifeline when defeat looms near."
    },

    -- Channeling
    ['MEDITATE'] = { 
        name = 'Meditate', 
        cost = 0, 
        type = 'channel', 
        color = {0.8, 0.8, 0.2, 1},
        description = "Enter a meditative trance to rapidly regenerate mana. While channeling, you cannot summon demons, but your mana pool refills at an accelerated rate. Break the channel by moving lanes or summoning."
    },
    ['SUCCUBUS'] = { 
        name = 'Succubus', 
        cost = 50, 
        color = {1, 0.4, 0.7, 1}, 
        width = 20, 
        height = 24, 
        speed = 10, 
        type = 'summon', 
        attackRange = 0,
        description = "A seductive demon with the power to charm heroes. When a Succubus reaches an enemy, she enchants them to fight for your cause. Charmed heroes turn against their former allies until slain."
    }
}

return Grimoire
