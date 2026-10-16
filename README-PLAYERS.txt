EchoVRCE Switcher
=================

Points your Echo VR game at a community server (with a game mode of your
choice), and switches it back to official EchoVRCE in one click.

YOU NEED
  - A working EchoVRCE Echo VR install (the one you already play on).

HOW TO USE
  1. Close Echo VR if it's open.
  2. Double-click  Switch.bat
       (If Windows shows "Windows protected your PC", click More info -> Run anyway.)
  3. The server address is already filled in. (If the box is ever empty, paste
     the address your host gave you.)
  4. Pick a GAME MODE from the dropdown:
       - Normal (stock physics) - plays like regular Echo.
       - Gravity     - you fall. Discs and other grabbable objects float like
                       normal until someone touches them, then they fall (a
                       thrown disc arcs down). Everyone in the match should
                       pick Gravity: a thrown disc or object follows the
                       thrower's game while it flies.
       - Super Speed - speed that builds. Your wrist thrusters push twice
                       as hard and top out at twice the normal speed - and
                       that top speed keeps rising the longer you hold near
                       it (about +1 m/s every second, no limit). Slow right
                       down and it drops back. Boost 4 times in a row (each
                       one a normal boost added on top of your speed); all 4
                       come back 3 s after your last one. Wall push-offs
                       launch you 1.5x as fast (up to 6 instead of 4).
                       Carrying the disc: no boosting, and the build-up is
                       half as quick, so the carrier is slower.
                       Powers - 5 s each, ready again 10 s after it ends:
                         X = unlimited boost: boost as often as you like
                             (boosts add speed up to 35 m/s).
                         A = ultimate thrusters: four times the push and
                             a top speed 15 m/s over yours (max 35 m/s).
                       Your controllers buzz when a power starts, ends and
                       is ready again, and when your 4 boosts come back.
                       X and A do nothing else in this mode.
       - Tiny (experimental) - a size changer. You start at your normal
                       size. Press X to get smaller, A to get bigger, one step
                       at a time:  1/4, 1/2, normal, 2x, 3x  in a match (it
                       grows or shrinks smoothly over about half a second).
                       In the LOBBY you can also go down to 1/10. Going into
                       a match at 1/10, you snap to 1/4. A buzz =
                       size changed; two weak buzzes = already as small / as
                       big as it goes. Everything follows your size: what you
                       see, your body and hands, how far you can reach, grab
                       and punch, and your thrusters, boosts, push-offs and
                       the speed limit while carrying the disc.
                       Bigger is also a bit faster for its size (2x moves
                       2.2x as fast, 3x about 3.5x); smaller is a bit slower
                       (1/10 moves about 1/15 as fast).
                       Your body takes a few seconds after you load in to
                       follow (just look around).
                       KNOWN ISSUE: when you are not normal size, holding on
                       to a wall can slip - your grab lets go and catches
                       again lower down (or higher up when you are big).
                       WHAT OTHERS SEE (new, not tested with two players
                       yet): anyone on Tiny, Strength, Stretch, Blink or
                       Spider-Man sees your avatar at your size - it grows
                       and shrinks with you a moment after you press X or
                       A, and your name tag keeps following you (it stays
                       normal size). Players on
                       Normal, Gravity or Super Speed (or without this
                       download) still see a normal-size body with your
                       hands bunched in. Only the look changes: in their
                       game you can still be hit where a normal-size body
                       would be.
                       X and A do nothing else in this mode.
       - Strength (experimental) - your throws (disc and objects) are a bit
                       faster, and people you punch stay stunned about 2.5 s
                       longer.
                         POWER THROW: while holding the disc (or anything
                         you can throw), hold A (right hand) or X (left).
                         Your controller hums as it charges (about 1 s),
                         then BUZZES HARD - that is the sweet spot (about
                         0.4 s): throw then for up to 1.5x speed. Wait too long
                         and it pulses weakly as the power drains away.
                         Everyone sees the throw. A power-thrown disc pulls
                         you after it: just after it leaves your hand (so
                         the throw itself isn't touched) you lunge forward
                         the way it went - up to 8 m/s at full power.
                         TACKLE: TAP A (quick press, not a hold) and you lock
                         onto the player most in front of you (within 10 m)
                         and charge at them at 15 m/s. Reach them and they're
                         stunned 1.5 s. 15 s cooldown (buzz when it's back).
                         The stun arms itself the first time you land a
                         normal punch in a match.
                       A and X do nothing else here.
       - Stretch (experimental) - rubber arms. Hold X to stretch your left
                       arm, A for your right: it shoots out to 5x your reach
                       (aim by reaching), and reels back in when you let go.
                       Grab a wall far away and let go of the button to be
                       pulled to it; grab the disc far away and let go to reel
                       it in.
                         Both X and A held = both arms at 2.5x.
                         STRETCH DASH: DOUBLE-TAP X or A (press, let go,
                         press again - quickly): that arm snaps out and yanks
                         you 5 m the way that controller points, and you
                         keep going that way. 5 s cooldown per arm (a buzz
                         when it's back).
                         STICKY CATCH: if the disc comes within 1 m of a
                         stretched hand, that hand snags it (unless you're
                         gripping something with it). It's held for you while
                         the arm is out and reels in - squeeze your grip to
                         keep it once it's back.
                         SPRING PUSH-OFF: push off a wall with a stretched
                         arm and you launch 2.5x harder (up to 10 m/s).
                         RUBBER PUNCH: punch with a stretched arm and it
                         stuns 2 s longer.
                       X and A do nothing else in this mode.
       - Blink (experimental) - for 1v1s and team games.
                         DECOY (A): for 5 s everyone else - on any mode,
                         either team, with or without the mod - sees a
                         frozen copy of you standing where you pressed A,
                         name tag and all, while the real you moves around
                         unseen. Then you reappear where you really are.
                         PHANTOM SPRINT: while the decoy is up, your
                         thrusters and boost are 1.5x.
                         Ready again 10 s after you reappear. A disc you
                         hold still shows where you really are, and a punch
                         on the decoy stuns the real you.
                         What YOU see: a hologram of yourself in your team's
                         colour, frozen where your decoy stands, and a
                         cloak ring round each wrist that runs down with the
                         5 s (it pulses fast in the last second). You never
                         go invisible on your own screen.
                         SNAP BACK (A again while the decoy is up): you
                         fly back along the exact path you took and stop
                         dead where your decoy stands - to everyone else
                         you never moved. Ends the decoy (A ready 10 s
                         later).
                         MOMENTUM BLINK (X): jump 6 m the way you are
                         looking and come out with ALL the speed you had
                         plus a bit more (20% faster, at least +1.5 m/s),
                         turned the way you are looking. You have TWO
                         blinks; each comes back 10 s after you used it.
                         AFTERBURN: for 1.5 s after every blink your
                         thrusters push twice as hard (3x if your decoy is
                         up too).
                       Your controllers buzz when a power fires, when you
                       reappear, and when a power is ready again. X and A do
                       nothing else in this mode.
       - Spider-Man (experimental) - hold X (left) or A (right) to shoot a
                       web where that controller points (up to 50 m); it
                       sticks to the first thing it hits and lets go when you
                       let go of the button. The web is a rope: it swings you
                       around what it is stuck to and keeps all your speed.
                       Squeeze grip on that hand to reel in - it speeds up the
                       longer you hold it; let go of grip to stop. That hand
                       will not grab while its web is out.
                         THE DISC: web the disc when it is within 5 m
                         and it comes to you - your hand shoots out on
                         the web, grabs it, and reels it back into your
                         hand. It STAYS in your hand until you squeeze your
                         grip (then it's yours - let go of grip to throw) or
                         tap that web button again (drops it). If the grab
                         missed, your hand reaches for it once more. The ring
                         doubles when your next web would grab the disc
                         (you don't have to hit it exactly). Farther than
                         5 m, the web just sticks to it like anything else.
                       A ring shows where
                       each free hand's next web would land (it follows your
                       aim smoothly); your webs are
                       braided strands with a splat where they stuck, in your
                       team's colour (white on no team). Only you see them so
                       far. A quick red flash = missed. Buzz = web stuck; two
                       weak buzzes = missed.
                         WEB FLING: let go of a web while you're moving fast
                         (5 m/s or more) and you're flung out 25% faster
                         (up to 25 m/s).
                         WEB ZIP: double-tap the web button (let go, press
                         again within a quarter second) and you zip straight
                         at where the web is stuck at 15 m/s; it lets go just
                         before you arrive.
                         SPIDER-SENSE: a quick double buzz on the side when
                         another player is close behind you (within 4 m and
                         closing, or within 2 m). Teammates count too.
                         WEB SNARE: web another player and they're stunned
                         for 1.5 s (10 s cooldown). It arms itself the first
                         time you land a punch in a match - until then a
                         web on a player is just a web.
     NO POWERS IN THE BUBBLE: in a match, while your team is held in the
     spawn bubble (before the match, the countdown before each launch, the
     team room, before sudden death), A and X do nothing in every power
     mode. They work again the moment you launch. The lobby is not a
     bubble - powers always work there.
     TINY PLAYERS AT THEIR SIZE: on Tiny, Strength, Stretch, Blink and
     Spider-Man you see someone playing Tiny at the size they picked.
     More modes may be added later.
  5. Click  "Connect to this server".
       - First time, it asks for your Echo VR folder: pick the one that
         contains  bin\win10\echovr.exe  (not inside bin).
  6. Start Echo VR. That's it - if you picked a mode with a mod, it turns on by
     itself every time you launch Echo. You never run anything by hand while
     the game is open. To change modes, close Echo, pick another, Connect.
  7. First time only: the game shows a LINK CODE. In the Discord server, type
     /link-headset and enter that code.

GO BACK TO ECHOVRCE (OFFICIAL)
  - Open Switch.bat and click the big green  "Back to EchoVRCE (official)"
    button. It restores your original settings exactly and turns any mod off.

NOTES
  - Anything you type is saved only on your PC (my-server.txt next to this
    tool). The host's real IP is not in this download.
  - Mod modes keep a tiny helper running so the mod re-applies whenever you
    start Echo (even after a reboot). The "Back to EchoVRCE" button removes it.
