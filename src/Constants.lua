-- Global constants for the game

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

GAME_VERSION = "0.1.11"
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
        ['WALK']    = { texture = 'imgs/Knight/Knight_Run.png', frames = 6, duration = 0.1, scale = 0.2 },
        ['IDLE']    = { texture = 'imgs/Knight/Knight_Idle.png', frames = 8, duration = 0.1, scale = 0.2 },
        ['ATTACK1'] = { texture = 'imgs/Knight/Knight_Attack1.png', frames = 4, duration = 0.1, scale = 0.2 },
        ['ATTACK2'] = { texture = 'imgs/Knight/Knight_Attack2.png', frames = 4, duration = 0.1, scale = 0.2 },
        ['GUARD']   = { texture = 'imgs/Knight/Knight_Guard.png', frames = 6, duration = 0.1, scale = 0.2 }
    }
}
