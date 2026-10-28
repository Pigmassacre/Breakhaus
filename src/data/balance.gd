class_name Balance
## Every number worth tuning, in one place. Distances are in board units:
## one art pixel is PX units, and the board is COLS blocks wide.

# --- the board ----------------------------------------------------------------------------------
## One art pixel. The original game drew everything at 4x, and so does this.
const PX := 4.0
const COLS := 12
const BLOCK_W := 12.0 * PX
## A block's footprint on the board, front to back; its front face is BLOCK_DEPTH tall on top of that.
const ROW_H := 6.0 * PX
const BLOCK_DEPTH := 2.0 * PX
const ROWS := 36
const BOARD_W := COLS * BLOCK_W
const BOARD_H := ROWS * ROW_H
## A block whose row reaches this one is over the line, and the game is over.
const DEATH_ROW := 26
const WALL := 3.0 * PX

# --- the paddle ---------------------------------------------------------------------------------
const PADDLE_Y := BOARD_H - 16.0 * PX
const PADDLE_H := 6.0 * PX
const PADDLE_DEPTH := 2.0 * PX
const PADDLE_W := 26.0 * PX
const PADDLE_W_WIDE := 40.0 * PX
const PADDLE_W_NARROW := 16.0 * PX
## How quickly the paddle closes on where it is told to be (per second, as a lerp rate).
const PADDLE_FOLLOW := 22.0
## Keys and sticks: top speed and how fast it gets there.
const PADDLE_SPEED := 1250.0
const PADDLE_ACCEL := 9000.0
## The angle off straight up at the paddle's very edge.
const PADDLE_MAX_ANGLE := deg_to_rad(64.0)
## How much of the paddle's own speed goes into the ball's angle.
const PADDLE_ENGLISH := 0.00022
## Spin: a moving paddle sets the ball turning, this much per unit of the paddle's speed, up to
## SPIN_MAX radians a second, dying away at SPIN_DECAY (so a curve of SPIN_MAX / SPIN_DECAY at most).
const SPIN_FROM_PADDLE := 0.0011
const SPIN_MAX := 1.4
const SPIN_DECAY := 2.2
## A ball that comes up under the paddle is knocked down and out at this angle below the flat:
## shallow, so it gets out from under in a bounce or two.
const PADDLE_UNDER_ANGLE := deg_to_rad(20.0)

# --- smashing -----------------------------------------------------------------------------------
## The paddle hops up this far for SMASH_TIME after a smash press; a ball met in that time is smashed.
const SMASH_TIME := 0.2
const SMASH_COOLDOWN := 0.32
const SMASH_HOP := 4.0 * PX
const SMASH_SPEED := 1120.0
## A smashed ball goes straight through this many blocks it breaks.
const SMASH_PIERCE := 3

# --- the ball -----------------------------------------------------------------------------------
const BALL_R := 3.0 * PX
const BALL_SPEED := 520.0
const BALL_SPEED_MAX := 980.0
## Added on every paddle hit, up to BALL_SPEED_MAX.
const BALL_SPEED_PADDLE := 40.0
## The ball never goes flatter than this off the horizontal, so it can't rattle side to side forever.
const BALL_MIN_ANGLE := deg_to_rad(16.0)
const BALL_STEP := BALL_R * 0.5
const MAX_BALLS := 24

# --- waves --------------------------------------------------------------------------------------
## Seconds between the wall coming down a row: on the first floor, and the fastest it gets.
const WAVE_TIME := 8.0
const WAVE_TIME_MIN := 4.0
## Taken off WAVE_TIME for every floor down.
const WAVE_TIME_STEP := 0.5
## A miss lets the wall come on: this much of a wave at once.
const MISS_PUSH := 0.5
## The blocks shake for this long before they come down.
const WAVE_RUMBLE := 1.2
## Rows a floor starts with, and rows still to come on it (more on each floor).
const START_ROWS := 5
const START_ROWS_MAX := 9
const QUEUE_ROWS := 7
const QUEUE_ROWS_MAX := 16
## The haus is this many floors tall; past the ground floor come the basements, for ever.
const FLOORS := 8
## How close the wall is (in rows above the line) when the danger shows and the alarm goes.
const DANGER_ROWS := 4
const CRITICAL_ROWS := 1

# --- blocks -------------------------------------------------------------------------------------
const STEEL_HP := 5
## Every block has this chance of carrying a pickup, prize blocks aside (they always do).
const DROP_CHANCE := 0.015
## A burning block takes a hit this often, and passes the fire on to a neighbour this often.
const BURN_TICK := 0.9
const BURN_SPREAD := 0.35
## How far a TNT block's blast reaches, in blocks.
const TNT_RADIUS := 1
## A bumper's kick: the ball's speed goes up this much (up to BALL_SPEED_MAX), and it scores this.
const BUMPER_HP := 3
const BUMPER_KICK := 220.0
const SCORE_BUMP := 25
## A fuse, once lit by a ball: seconds until it goes (lit by a blast, much sooner).
const FUSE_TIME := 2.2
const FUSE_CHAIN := 0.25
## A coin block is worth COIN_MAX as it lands, down to COIN_MIN after COIN_DRAIN seconds.
const COIN_MAX := 800
const COIN_MIN := 40
const COIN_DRAIN := 20.0

# --- scoring ------------------------------------------------------------------------------------
const SCORE_BLOCK := 10
const SCORE_GOLD := 250
const SCORE_FLOOR := 2500
## Sweeping the board clean with rows still to come: this, and SWEEP_ROWS rows rain in at once
## (taken off the rows to come, and made up with new ones if fewer are left).
const SCORE_SWEEP := 2000
const SWEEP_ROWS := 6
## Each floor down is worth this much more, on everything.
const SCORE_FLOOR_MULT := 0.25
## The combo: every break adds one; it lasts COMBO_TIME without a break, and a miss ends it.
const COMBO_TIME := 2.4
## Every COMBO_STEP breaks raise the multiplier by one, up to COMBO_MULT_MAX.
const COMBO_STEP := 6
const COMBO_MULT_MAX := 8
## Reaching COMBO_MULT_MAX sets off Fever, once a combo: this long, the balls ploughing through
## everything but steel and every point doubled. A miss puts it out.
const FEVER_TIME := 8.0

# --- the quake ----------------------------------------------------------------------------------
## Breaks it takes to charge (a combo charges it faster), and how many rows it brings down.
const QUAKE_CHARGE := 120.0
## A ball let through to the bottom (not off a shield) drains this much of the charge.
const QUAKE_MISS := 30.0
const QUAKE_ROWS := 3

# --- pickups ------------------------------------------------------------------------------------
const PICKUP_FALL := 70.0
const PICKUP_SIZE := 9.0 * PX
const FIRE_TIME := 9.0
const FROST_TIME := 9.0
const ZAP_TIME := 12.0
const ZAP_ARCS := 2
const ZAP_REACH := 3.5 * BLOCK_W
const WIDE_TIME := 15.0
const NARROW_TIME := 10.0
const OVERDRIVE_TIME := 10.0
const OVERDRIVE_SPEED := 1.25
const ROCKET_TIME := 9.0
const ROCKET_RATE := 0.42
const ROCKET_SPEED := 900.0
const SHIELD_TIME := 15.0
const MULTI_BALLS := 2
## Rocket Barrage: this many rockets, one after another, each off to a column of its own.
const BARRAGE_ROCKETS := 14
const BARRAGE_GAP := 0.05
## Laser: how long, and how often it hits the block it is burning into.
const LASER_TIME := 4.0
const LASER_TICK := 0.07
## Magnet: how long; a ball it catches is let go after MAGNET_HOLD, or when you smash.
const MAGNET_TIME := 12.0
const MAGNET_HOLD := 1.5
## Blast Ball: how long every block a ball hits goes off, knocking its neighbours.
const BLAST_TIME := 8.0
## Hurry Up (a bad one): how long the wall comes down this many times as fast.
const HASTE_TIME := 8.0
const HASTE_SPEED := 2.0

# --- feel ---------------------------------------------------------------------------------------
## Freezes the game for a moment on a big hit (seconds).
const HITSTOP_BREAK := 0.018
const HITSTOP_BIG := 0.07
