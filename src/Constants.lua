-- Global constants for the game

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

GAME_VERSION = "0.1.13"
UPDATE_URL = "https://niconachoo.github.io/DunZum/version.json" -- GitHub Pages URL

-- Gameplay Constants
NUM_LANES = 5
LANE_HEIGHT = 28 -- Adjusted for background shelves
LANE_OFFSET = 52 -- Push down below the top statue/column area

NUM_SLOTS = 5
SLOT_WIDTH = 40
SLOT_PADDING = 10

HERO_SPAWN_RATE = 4 -- Seconds between spawns

HERO_ANIMATIONS = {
    ['KNIGHT'] = {
        ['WALK']    = { texture = 'imgs/Knight/Knight_Run.png', frames = 6, duration = 0.075, scale = 0.2 },
        ['IDLE']    = { texture = 'imgs/Knight/Knight_Idle.png', frames = 8, duration = 0.075, scale = 0.2 },
        ['ATTACK1'] = { texture = 'imgs/Knight/Knight_Attack1.png', frames = 4, duration = 0.075, scale = 0.2 },
        ['ATTACK2'] = { texture = 'imgs/Knight/Knight_Attack2.png', frames = 4, duration = 0.075, scale = 0.2 },
        ['GUARD']   = { texture = 'imgs/Knight/Knight_Guard.png', frames = 6, duration = 0.075, scale = 0.2 }
    },
    ['PRIEST'] = {
        ['WALK']   = { texture = 'imgs/Healer/Healer_Run.png', frames = 4, duration = 0.075, scale = 0.2 },
        ['IDLE']   = { texture = 'imgs/Healer/Healer_Idle.png', frames = 6, duration = 0.075, scale = 0.2 },
        ['ATTACK'] = { texture = 'imgs/Healer/Healer_Heal.png', frames = 11, duration = 0.075, scale = 0.2 },
        ['GUARD']  = { texture = 'imgs/Healer/Healer_Idle.png', frames = 6, duration = 0.075, scale = 0.2 }, -- Fallback
        ['HEAL_EFFECT'] = { texture = 'imgs/Healer/Heal_Effect.png', frames = 11, duration = 0.075, scale = 0.2 },
        ['ATTACK_EFFECT'] = { texture = 'imgs/Healer/Attack_Effect.png', frames = 11, duration = 0.075, scale = 0.2 }
    },
    ['ARCHER'] = {
        ['WALK']   = { texture = 'imgs/Archer/Archer_Run.png', frames = 4, duration = 0.075, scale = 0.2 },
        ['IDLE']   = { texture = 'imgs/Archer/Archer_Idle.png', frames = 6, duration = 0.075, scale = 0.2 },
        ['ATTACK'] = { texture = 'imgs/Archer/Archer_Shoot.png', frames = 8, duration = 0.075, scale = 0.2 },
        ['GUARD']  = { texture = 'imgs/Archer/Archer_Idle.png', frames = 6, duration = 0.075, scale = 0.2 }, -- Fallback
        ['PROJECTILE'] = { texture = 'imgs/Archer/Arrow.png', scale = 0.3 }
    },
    ['ASSASSIN'] = {
        ['WALK']   = { texture = 'imgs/Assassin/Assassin_Run.png', frames = 6, duration = 0.075, scale = 0.2 },
        ['IDLE']   = { texture = 'imgs/Assassin/Assassin_Idle.png', frames = 8, duration = 0.075, scale = 0.2 },
        ['ATTACK'] = { texture = 'imgs/Assassin/Assassin_Attack.png', frames = 4, duration = 0.075, scale = 0.2 },
        ['GUARD']  = { texture = 'imgs/Assassin/Assassin_Idle.png', frames = 8, duration = 0.075, scale = 0.2 }, -- Fallback
    }
}
