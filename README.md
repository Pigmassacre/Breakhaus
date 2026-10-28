# Breakhaus

Break the haus before it breaks you.

Breakhaus is a brick breaker where the wall comes down on you, made in
Godot 4.7.2. The blocks come down a row at a time, on a clock; let them
cross the red line and the haus wins. Keep its bottom rows broken to keep
it off the line; every ball you let past your paddle lets it gain on you. Clear a floor and you crash through it to the next: eight floors from
the penthouse to the lobby, and then the basements, for ever. It plays
with a keyboard, a mouse, a gamepad or a finger, on Windows, Linux,
Android and in a browser.

It began as a libGDX game, years ago, and was never finished: the Java is
in this repository's history (tag `libgdx-original`). This is a rewrite
from scratch rather than a port, keeping its idea (the wall coming down on
a timer, the ball that never dies, the fake 3D of things with a height and
a shadow, blocks raining in from the sky and hopping in a ripple when one
is hit), its sprites and a few of its sounds, and finishing it.
Every number worth tuning is in one place, `src/data/balance.gd`.

## Running

```sh
../Godot/Godot_v4.7.2-stable_linux.x86_64 --path .
```

Or open the folder in the Godot 4.7 editor and press Play. It uses the
Compatibility renderer everywhere, so the same game runs on a desktop, a
phone and in WebGL 2.

### Building

```sh
./build_game.sh
```

exports every preset in `export_presets.cfg` whose export template is
installed (Windows, Linux, Web and Android) into `builds/<preset>/`, with
the engine's notices (`GODOT_COPYRIGHT.txt`) and `CREDITS.txt` beside the
game; a preset without its template is skipped, with a line saying so.
`./build_game.sh Web Linux` builds just those (and fails if one of them
can't be built); `--zip` also makes `builds/Breakhaus-<preset>-<commit>.zip`
of each. It imports and checks every script compiles first, as an export
lets broken ones through, and draws the Windows icon, `icon.ico`, from
`icon.svg` (`tools/make_icon.gd`). The commit goes into the build as
`commit.txt` for the title's version (run from the project, the game asks
git instead). `build_game.bat` does the same on Windows. It uses the stock
editor in `../Godot/` and its installed 4.7.2 export templates.

- **Web** is the single-threaded build (`web_nothreads_release.zip`), so it
  runs on itch.io and anywhere else without the cross-origin isolation
  headers threads need. `builds/Web/index.html` is the page.
- **Android** needs the Android export template, and the Android SDK and a
  JDK set in the editor's settings (Editor Settings > Export > Android). A
  release build is signed with the keystore in
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`
  and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`; without them the script
  builds it signed with the debug key, which is fine for trying it on a
  phone but not for a store. The APK is for arm64 and 32-bit arm, portrait,
  full screen (immersive), and asks for nothing but the vibrator.

### Releasing to itch.io

```sh
./build_game.sh
./upload_to_itchio.sh
```

pushes each build there is to its channel on
[pigmassacre/breakhaus](https://pigmassacre.itch.io/breakhaus) with butler
(`builds/Windows/` to `windows`, `builds/Linux/` to `linux`, `builds/Web/`
to `html5`, `builds/Android/` to `android`), versioned `config/version`
from `project.godot`; the Windows exe takes its version from there too.
`./upload_to_itchio.sh Web` pushes just the one. Every build named is
checked before anything goes up, and a build that hasn't changed isn't
pushed again. `--dry-run` shows what the page has now and what would go
up, and pushes nothing; `--status` just shows what the page has. The web
build has to be marked "played in the browser" on the page once, by hand
(a portrait viewport, 720 by 1280 or smaller, suits it). butler is the one
in `butler-linux-amd64/` or `butler-windows-amd64/` beside the repo, or
GoreDash's; it signs in with the key in
`~/.config/itch/butler_olofkarlsson_creds`, or asks to log in without it.
`upload_to_itchio.bat` does the same on Windows.

## Playing

**The wall.** A floor starts with a few rows of blocks raining down out of
the sky, one row after another, then the paddle and the ball drop in. The
bar over the board fills, and when it is full the whole wall comes down a
row and a new row rains in at the top, until the floor has none left to
send (the count is under the floor's name). The blocks shake for a moment
before they come down when the wall is getting close. If any block reaches
the red line, the game is over. Nothing holds the bar back: the clock is
the clock, and the only way to keep the wall off the line is to keep
breaking its bottom rows.

**The ball never dies.** It bounces off the bottom of the board as off any
wall, as in the original. But that's a miss: the ball is back to its
slowest, your combo is gone, the wall jumps half the way to coming
down, and the screen flashes red. With more than one ball in play, those
that go past the paddle are simply gone, until there is one left.

**The paddle** sends the ball off at an angle by where on it the ball
lands (straight up from the middle, up to 64 degrees off at the edges),
bent a little by how fast the paddle is moving. Every hit makes the ball a
little faster, up to its top speed.

**Smash.** Press smash (or click, or tap) and the paddle hops for a fifth
of a second. A ball that meets it then is smashed: it flies off at more
than its top speed, glowing yellow, and goes straight through the next
three blocks it breaks, with a hitstop, a shake and a shock wave. The top
of the paddle lights up yellow while a ball is about to land on it: that's
the moment. Smash also launches the ball at the start of a floor.

**Combo.** Every block broken adds to the combo; it lasts 2.4 seconds
without a break, and a miss ends it. Every six breaks raise the
multiplier, up to x8, and the breaking sound climbs a note each time. A
combo of 10, 20, 30 ... gets a fanfare.

**Fever.** The first time a combo reaches x8, Fever sets in for eight
seconds (`FEVER_TIME`): the balls plough straight through everything but
steel, every point is doubled again, the balls trail a rainbow, the rays
behind the board turn every colour and spin, and the music goes flat out.
A miss puts it out; the next combo can light it again.

**The quake.** Breaking blocks charges the meter under the board (a combo
charges it faster). When it is full the paddle hums, and the quake (Shift,
right click, Y, or the button on a touch screen) brings down the bottom
three rows of the wall at once, from the bottom up, and knocks the wave
bar back to empty. It is the way out when the wall is at the line.

**The floors.** Clearing a floor's last block clears it: a bonus, a burst
of light, the glass cracking from the middle out and falling away into
the dark, and you fall after it, the dust rushing up past you: the floor
below comes up out of the dark, small and dim, nearer and nearer, until
you land on it with a thump, a shock wave and a puff of dust round the
walls, and its blocks rain in. It is faster (the wall comes down half a
second sooner each floor, from 8 seconds to 4 at the quickest) and has
more rows to break. The floors are themed: the Penthouse (the original's
pink glass), the Offices (a glowing grid), the Disco (lit tiles), the
Library (planks), the Kitchen (tiles), the Greenhouse (green glass), the
Arcade (a neon grid) and the Lobby (marble); breaking through the Lobby
demolishes the haus, and the basements go on down for as long as you
last. On a wide screen the board is as tall as the screen, the floor and
the haus (the floor you are on lit up) to its left and the score and the
pickups running to its right; on a tall one (a phone) they are over it. A wall that is swept clean while the floor still has
rows to send is a Clean Sweep: a big bonus (`SCORE_SWEEP`), and six rows
(`SWEEP_ROWS`) rain in all at once, the floor's next six or, if it has
fewer left, those and new ones to make up six.

**Blocks.** Plain ones take one hit; studded ones a hit per stud and one
more. Steel takes five and won't burn. TNT goes off when it breaks, a
moment later, hitting everything round it (and other TNT, in a chain).
Prize blocks (a rainbow inside) always hold a pickup, and any block has a
small chance to (1.5%). Gold is worth a pile of points. Moss grows into an empty
cell beside it every time the wall comes down. The deeper floors bring
more of the tough kinds.

**Pickups** hang where they came out for a moment, then drift down; catch
one with the paddle or hit it with a ball. Each has a rarity
(`Pickups.RARITY_WEIGHT`): a common one is eight times as likely as a rare
one, an uncommon one about three times. The rarer, the louder: a column
of light rises out of an uncommon pickup (teal) and a rare one (gold,
taller, with sparkles going round it and a second ring); a rare drop
chimes, flashes and shouts RARE DROP!, and catching one is a fanfare. In
How to play each pickup sits in a frame of its rarity's colour with a tag
of stars, and the rare ones have a showcase page of their own, a sunburst
turning behind each. The icons the original had no sprite for are drawn
in code, row by row of art pixels (`Pickups.ICONS`).

| Pickup | Rarity | |
| --- | --- | --- |
| Wide Paddle | Common | A bigger paddle. |
| Shrink | Common | A smaller paddle: the one to dodge (a red ring pulses round it). |
| Overdrive | Common | Faster balls, double points. |
| Multiball | Uncommon | Every ball splits in three. |
| Zap | Uncommon | Every hit arcs lightning to the two blocks nearest. |
| Rockets | Uncommon | The paddle fires rockets, two at a time. |
| Rocket Barrage | Uncommon | Fourteen rockets in a salvo, each swinging off to a column with blocks in it and blowing a hole round where it lands. |
| Magnet | Uncommon | The paddle catches the ball; aim, then smash to let it go (or it goes by itself after a moment). |
| Blast Ball | Uncommon | Every block a ball hits goes off, knocking the eight round it. |
| Hurry Up | Uncommon | The bad one: the wave bar fills twice as fast for a while. |
| Fireball | Rare | Balls burn straight through blocks and set them alight; fire spreads. |
| Deep Freeze | Rare | The wall stops coming down, and every block shatters in one hit. |
| Shield | Rare | A barrier under the paddle: no misses. |
| Laser | Rare | A beam straight up from the paddle burns into whatever is over it, steel included, for 4 seconds. Near a wall it comes out of the paddle's end, so it reaches the edge columns. |

The ones that last show along the top of the board, each with the time it
has left.

**Scoring.** A block is worth 10 a hit it takes, gold 250, a floor 2,500;
everything is multiplied by the combo and by how deep you are (a quarter
more a floor), and doubled in Overdrive. The points fly off each block to
the score (the original's), which counts up to them. The ten best runs
are kept, with how deep each got.

### Modes

Play opens the modes (`src/data/modes.gd`), each described, with its best,
as it gets the focus:

- **Classic**: the haus floor by floor, and on into the basements.
- **Daily Haus**: today's haus. Its rows come from a generator of their own
  (`Board.row_rng`), seeded with the date, so they are the same for
  everyone who plays it that day however differently they play; pickups,
  moss and the ball's bounces are still left to chance. Each day also has
  a twist (`Modes.TWISTS`): Lucky Day (three times the pickups), Demolition
  Day (TNT everywhere), Gold Rush, Rush Hour (faster waves, points x1.5),
  Triple Trouble (every serve splits in three), Hard Hats (tougher blocks,
  more steel, points x1.5) or Overgrown (moss from the top floor down).
  The day's best is kept, and starts over the next day.
- **Rush**: three minutes on the clock and the wall at 70% of its usual
  wait. Clearing a floor adds 30 seconds and a Clean Sweep 10; the last
  ten tick down out loud. When the clock runs out, so does the game.

### Controls

| | Keys | Mouse | Pad | Touch |
| --- | --- | --- | --- | --- |
| Move | Arrows, A D | Move | Stick, d-pad | Drag anywhere |
| Smash, launch | Space, Up, W, Z | Left click | A, right trigger, RB | Tap |
| Quake | Shift, E, X | Right click | Y, X, left trigger, LB | Quake button |
| Pause | Esc, P | | Start, Back | II button, back |

The mouse puts the paddle where it is (and is hidden while you play);
keys and sticks drive it; a finger drags it from anywhere on the screen,
so it never covers the ball, and a touch anywhere smashes. The prompts
follow whatever you last touched. The menus work with all of them. F11 or
Alt+Enter is full screen. The game pauses when it loses the focus (a call
on the phone, alt-tab). On a phone the smash, the misses, the quake and
the end buzz it.

**Options**: music and sound volumes, screen shake (which also turns the
phone's buzzing off at zero), flashes (dimmed to a quarter when off), full
screen, and on a touch screen how far a drag moves the paddle.

## How it is made

```
src/main.gd            the root: one screen at a time, a curtain between them
src/autoload/          Inputs (actions, which device), Audio (sounds, layered music), Game (settings, scores)
src/data/              balance.gd (every number), floors.gd (themes, rows), pickups.gd, modes.gd
src/play/              the game: play.gd (the screen), board.gd (the rules), board_view.gd (drawing),
                       block.gd, ball.gd, block_art.gd, particles.gd, hud.gd, tower.gd, pause and game over
src/ui/                splash, title (logo.gd), how to play, high scores, options, ui_kit.gd, spring.gd
src/fx/                backdrop.gd and the screen-wide shaders
tools/                 import_audio.py, check_gdscript.gd, make_icon.gd, write_godot_copyright.gd
```

Nothing is a scene but `main.tscn`: every screen builds itself in code.
The board (`Board`) is plain rules over a grid of `Block`s and a list of
`Ball`s, its own little physics (the ball moves in steps of half its
radius, meeting the walls, the paddle, the nearest block, pickups and the
other balls in turn), and it tells the game what happened through
signals: shake, hitstop, flash, shock, a message, a score. `play.gd` turns
those into the feel: a trauma-based shake of the world, the board frozen
for a few hundredths of a second on a big hit, and the screen effects.
Everything on the board is drawn by `board_view.gd` in one pass, in art
pixels (4 units each, as the original drew its sprites at 4x): the walls,
every shadow (down and to the right, further the higher the thing is),
the blocks back to front (so a block hides the front face of the one
behind it), the pickups, the paddle, the balls and their trails, and a
thousand particles kept in packed arrays (`Particles`). Effects are drawn in whole
art pixels on the board's grid (`Pixels`: squares, rings and stepped
lines), so a pickup's ring, a spark or a bolt of lightning is made of the
same size of pixel as the sprites; the sprites themselves still move
smoothly, and the ball squashes into shapes of its own rather than
stretching its pixels.

**Pixels for the game, HD for the UI.** Everything on the board is pixel
art; the menus and the HUD around it are flat and smooth: big words in
Bungee (a face made for signs on buildings) and small print in Rubik
(rounded at the corners, like the buttons; both MSDF fonts, so they stay sharp at
any size and any scale a tween gives them), rounded buttons with a darker
lip they press down into, round pill bars and timer rings, and a flat
drawing of the haus. Every button, slider and switch has a `Spring` in it
(`src/ui/spring.gd`): three damped springs, on real time, so it swells
and breathes while it has the focus, leans toward the pointer over it,
squashes when pressed and boings back when let go.

**Shaders, not pictures.** The original spun a big image for its rays and
had its glass floor drawn; here they are worked out per art pixel, so they
stay crisp however they move.

- `src/play/floor.gdshader` is the board's floor: the pane of glass with
  its light streaks sliding by, or tiles (that light up in turn on the
  dance floor), planks, marble or a neon grid with a scan line. Rings
  spread from every hit and bend the pattern; a pool of light follows each
  ball; red rises to the line as the wall closes in; frost creeps in from
  the edges and fire flickers over it; and when a floor is cleared it
  cracks into Voronoi pieces from the middle out, and they drop away.
- `src/fx/sunrays.gdshader` is the backdrop: rays turning slowly round the
  board, darker in steps away from it, red in danger, with dust drifting
  up in three layers of parallax (the near one in bigger pixels, faster
  and brighter), each mote an art pixel or two but gliding smoothly, and
  rushing past as you fall between floors.
- `src/fx/post.gdshader` is over the whole game, under the HUD: a shock
  wave rippling out from a big hit, colour fringes with the shake, a flash
  for a pickup or a miss, a red vignette when the wall is close, and the
  original's grayscale for the end.
- `src/fx/curtain.gdshader` is the wipe between screens: tiles (squares,
  diamonds or dots) growing in one of seven orders, a new one each time; `src/ui/splash.gdshader` puts the
  Pigmassacre pig together tile by tile.

**Sound.** `Audio` loads every sound as the game starts and plays them
from a pool, no more than two of the same in a frame (a burst of breaks
doesn't roar). The breaking climbs a scale with the combo. The music is
Ovani's, each track in its three layers (sparse, busier, full: the same
piece) playing together in step and crossfading with the game's heat (how
close the wall is, how big the combo, how many pickups are running), and
muffled under the pause menu and the end. Each floor has its track.

### Testing without playing

```sh
../Godot/Godot_v4.7.2-stable_linux.x86_64 --path . -- --screen=play --autoplay --shots=5,20,60
```

- `--screen=<name>` starts on that screen (splash, title, play, help,
  scores, options); `--floor=3` starts the game on that floor (0 is the
  top), and `--mode=rush` (or `daily`, or `classic`) in that mode. The
  game starts on the title; the splash is skipped for now, as it is to be
  redone, but `--screen=splash` still shows it.
- `--autoplay` has the game play itself: the paddle follows the lowest ball
  down, smashes now and then and quakes when it is in trouble;
  `--autoplay=lazy` only launches the ball, and the wall wins.
- `--short-floors` makes every floor a single row, and `--clear-at=5`
  clears the floor after five seconds: for what comes between floors.
  `--sweep-at=5` breaks every block after five seconds, for a Clean Sweep,
  and `--all-effects` sets every timed pickup going at once (the badges).
  `--drop=laser,shield` hangs those pickups over the board and
  `--give=laser` catches them at once.
- `--mouse=1.5:800:400,2:800:460:click` moves the pointer to those window
  coordinates at those seconds (and clicks, with `:click`): for catching
  the menus' hover and press in screenshots.
- `--shots=1.5,4,9` saves a screenshot to `shots/` at each of those seconds
  and quits after the last; `--size=720x1280` sizes the window first.
- `tools/check_gdscript.gd` compiles every script (the build runs it).

## Assets

`tools/import_audio.py` makes `assets/audio/` from the sound libraries
next to the repo (`../Assets`) and the original game's own sounds
(`assets/audio/original/`): it picks, trims, levels and converts each
sound, and loops each music layer by folding its reverb tail back over its
start. Needs ffmpeg.

- Sprites (the ball, block, paddle and pickup icons) and the Pigmassacre
  splash: the original Breakhaus.
- Fonts: Bungee by David Jonathan Ross and Rubik, both under the SIL Open
  Font License 1.1, their licences beside them in `assets/fonts/`.
- Music: Ovani Sound's Electronic Music Pack Vol. 5 and 80s Music Pack.
- Sounds: Ovani Sound's Casual & Mobile and Retro Gaming sound packs, and
  the original's ball, block, select and activate sounds.

Credits are in `CREDITS.txt`, which ships with every build.
