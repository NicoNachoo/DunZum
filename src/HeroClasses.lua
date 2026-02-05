local HeroClasses = {
    ['KNIGHT'] = {
        name = 'Knight',
        hpMult = 2.0, -- Base 100 * 2 = 200
        speed = 10,
        damage = 10,
        range = 10,
        attackRate = 1.5,
        color = {0.8, 0.8, 0.8, 1}, -- Silver
        behavior = 'MELEE'
    },
    ['PRIEST'] = {
        name = 'Priest',
        hpMult = 0.8, -- 80
        speed = 15,
        damage = 5, -- Weak attack against enemies
        healAmount = 30, -- Significant heal
        range = 60,
        attackRate = 2.0,
        color = {1, 1, 0.8, 1}, -- White/Gold
        behavior = 'SUPPORT'
    },
    ['ARCHER'] = {
        name = 'Archer',
        hpMult = 1.0, -- 100
        speed = 15,
        damage = 8,
        range = 100,
        attackRate = 1.2,
        color = {0.4, 0.6, 0.2, 1}, -- Green
        behavior = 'RANGED',
        projectileSpeed = -150, -- Left
        projectileType = 'ARROW'
    },
    ['ASSASSIN'] = {
        name = 'Assassin',
        hpMult = 0.6, -- 60 (Glass Cannon)
        speed = 30,
        damage = 25,
        range = 10,
        attackRate = 0.8, -- Fast
        color = {0.5, 0, 0.5, 1}, -- Purple
        behavior = 'MELEE'
    },
    ['MAGE'] = {
        name = 'Mage',
        hpMult = 0.9, -- 90
        speed = 10,
        damage = 20,
        range = 80,
        attackRate = 2.5, -- Slow powerful shots
        color = {0.2, 0.6, 1, 1}, -- Blue
        behavior = 'RANGED',
        projectileSpeed = -100,
        projectileType = 'FIREBALL' -- Or MagicBall
    }
}

return HeroClasses
