module Simulation

import SDL3

import Data.Bits

%default total

public export
record Ball where
  constructor MkBall
  x, y, vx, vy, radius : Double
  color : Color

public export
record Scene where
  constructor MkScene
  balls : List Ball
  count : Nat
  seed : Bits64

export
emptyScene : Bits64 -> Scene
emptyScene seed = MkScene [] 0 seed

-- A small deterministic generator for this example, not for security.
-- Use the high 32 bits of a 64-bit linear congruential generator.
randomUnit : Bits64 -> (Double, Bits64)
randomUnit seed =
  let next = seed * 6364136223846793005 + 1442695040888963407
   in (cast (next `shiftR` 32) / 4294967296, next)

newBall : Bits64 -> (Ball, Bits64)
newBall seed =
  let (size, s1) = randomUnit seed
      (px, s2) = randomUnit s1
      (py, s3) = randomUnit s2
      (angle, s4) = randomUnit s3
      (speed, s5) = randomUnit s4
      (red, s6) = randomUnit s5
      (green, s7) = randomUnit s6
      (blue, s8) = randomUnit s7
      (opacity, s9) = randomUnit s8
      radius = 8 + 28 * size
      velocity = 80 + 140 * speed
      alpha : Bits8 = if opacity < 0.4 then cast (90 + 280 * opacity) else 255
      color = MkColor (cast (70 + 185 * red)) (cast (70 + 185 * green))
                      (cast (70 + 185 * blue)) alpha
   in (MkBall (radius + px * (800 - 2 * radius)) (radius + py * (600 - 2 * radius))
              (velocity * cos (2 * pi * angle)) (velocity * sin (2 * pi * angle)) radius color, s9)

addBalls : Nat -> Scene -> Scene
addBalls Z scene = scene
addBalls (S n) (MkScene balls count seed) =
  let (ball, next) = newBall seed
   in addBalls n (MkScene (ball :: balls) (S count) next)

public export
data Command = AddBalls | ClearBalls | QuitApp | NoChange

export
Eq Command where
  AddBalls == AddBalls = True
  ClearBalls == ClearBalls = True
  QuitApp == QuitApp = True
  NoChange == NoChange = True
  _ == _ = False

export
applyCommand : Command -> Scene -> Scene
applyCommand AddBalls scene = addBalls 10 scene
applyCommand ClearBalls scene = emptyScene scene.seed
applyCommand _ scene = scene

export
commandFor : WindowID -> Event -> Either String Command
commandFor identifier event = case event of
  QuitEvent _ => Right QuitApp
  WindowCloseEvent _ target => Right (if target == identifier then QuitApp else NoChange)
  KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False) =>
    Right $ if target /= identifier then NoChange
      else if key == MkKeycode 110 || key == MkKeycode 78 then AddBalls -- n / N
      else if key == MkKeycode 99 || key == MkKeycode 67 then ClearBalls -- c / C
      else if key == MkKeycode 113 || key == MkKeycode 81 || key == escapeKey then QuitApp
      else NoChange
  RenderTargetsResetEvent _ target => reset target
  RenderDeviceResetEvent _ target => reset target
  _ => Right NoChange
  where
    reset : WindowID -> Either String Command
    reset target = if target == identifier
      then Left "Renderer reset. Restart balls to recreate the texture and text resources."
      else Right NoChange

-- The caller clamps elapsed time. A ball moves at most 22 units per update,
-- far less than either wall separation, so at most one hit per axis is possible.
reflect : Double -> Double -> Double -> Double -> (Double, Double, Nat)
reflect low high position velocity =
  if position <= low && velocity < 0 then (2 * low - position, -velocity, 1)
  else if position >= high && velocity > 0 then (2 * high - position, -velocity, 1)
  else (position, velocity, 0)

export
stepBall : Double -> Ball -> (Ball, Nat)
stepBall seconds ball =
  let dt = max 0 (min 0.1 seconds)
      (x, vx, hx) = reflect ball.radius (800 - ball.radius) (ball.x + ball.vx * dt) ball.vx
      (y, vy, hy) = reflect ball.radius (600 - ball.radius) (ball.y + ball.vy * dt) ball.vy
   in if dt == 0 then (ball, 0)
      else (MkBall x y vx vy ball.radius ball.color, hx + hy)

export
advance : Double -> Scene -> (Scene, Nat)
advance seconds scene =
  let (balls, hits) = move scene.balls [] 0
   in ({ balls := balls } scene, hits)
  where
    move : List Ball -> List Ball -> Nat -> (List Ball, Nat)
    move [] result hits = (reverse result, hits)
    move (ball :: rest) result hits =
      let (next, count) = stepBall seconds ball
       in move rest (next :: result) (hits + count)

export
frameDelay : Bits64 -> Bits64
frameDelay elapsed = if elapsed < 16666667 then 16666667 - elapsed else 0
