module Tests

import SDL3

import Simulation

import Data.List

import System

%default covering

check : String -> Bool -> IO ()
check name True = pure ()
check name False = die ("Balls test failed: " ++ name)

near : Double -> Double -> Bool
near a b = abs (a - b) < 0.000001

inside : Ball -> Bool
inside ball = ball.radius >= 8 && ball.radius <= 36 &&
  ball.x >= ball.radius && ball.x <= 800 - ball.radius &&
  ball.y >= ball.radius && ball.y <= 600 - ball.radius

sameBall : Ball -> Ball -> Bool
sameBall a b = a.x == b.x && a.y == b.y && a.vx == b.vx && a.vy == b.vy &&
               a.radius == b.radius && a.color == b.color

spawnMany : Nat -> Scene -> Scene
spawnMany Z scene = scene
spawnMany (S n) scene = spawnMany n (applyCommand AddBalls scene)

manySteps : Nat -> Scene -> Bool
manySteps Z scene = True
manySteps (S n) scene =
  let (next, _) = advance (1 / 60) scene
   in all inside next.balls && next.count == scene.count && manySteps n next

reflection : String -> Ball -> Double -> Double -> Double -> Double -> Nat -> IO ()
reflection name ball x y vx vy hits = do
  let (next, actualHits) = stepBall 0.02 ball
  check name (near next.x x && near next.y y && near next.vx vx && near next.vy vy && actualHits == hits)

physics : IO ()
physics = do
  let color = MkColor 100 150 200 128
  reflection "left wall preserves overshoot" (MkBall 11 300 (-100) 0 10 color) 11 300 100 0 1
  reflection "right wall" (MkBall 789 300 100 0 10 color) 789 300 (-100) 0 1
  reflection "top wall" (MkBall 400 11 0 (-100) 10 color) 400 11 0 100 1
  reflection "bottom wall" (MkBall 400 589 0 100 10 color) 400 589 0 (-100) 1
  reflection "corner has two wall hits" (MkBall 11 11 (-100) (-100) 10 color) 11 11 100 100 2
  reflection "inward motion does not bounce twice" (MkBall 10 300 100 0 10 color) 12 300 100 0 0
  reflection "exact contact reverses direction" (MkBall 12 300 (-100) 0 10 color) 10 300 100 0 1
  let ball = MkBall 100 300 100 0 10 color
  let (clamped, _) = stepBall 10 ball
  check "long stalls clamp to 100 ms" (near clamped.x 110)
  let (paused, noHits) = stepBall 0 ball
  check "zero elapsed time" (sameBall paused ball && noHits == 0)
  let (backwards, _) = stepBall (-1) ball
  check "negative elapsed time" (sameBall backwards ball)
  let (whole, _) = stepBall 0.04 ball
  let (half, _) = stepBall 0.02 ball
  let (halves, _) = stepBall 0.02 half
  check "motion follows time rather than frame count" (near whole.x halves.x)
  check "full frame budget" (frameDelay 0 == 16666667)
  check "one nanosecond remains" (frameDelay 16666666 == 1)
  check "slow frames do not underflow" (frameDelay 16666667 == 0 && frameDelay 0xffffffffffffffff == 0)

keyboard : WindowID -> Bits32 -> Bool -> KeyAction -> Event
keyboard target key repeated action =
  KeyboardEvent 0 (MkKeyboardData target action (MkScancode 0) (MkKeycode key) (MkKeyModifiers 0) repeated)

controls : IO ()
controls = do
  let mine = MkWindowID 1
  let other = MkWindowID 2
  check "n adds" (commandFor mine (keyboard mine 110 False Pressed) == Right AddBalls)
  check "uppercase N adds" (commandFor mine (keyboard mine 78 False Pressed) == Right AddBalls)
  check "c clears" (commandFor mine (keyboard mine 99 False Pressed) == Right ClearBalls)
  check "uppercase C clears" (commandFor mine (keyboard mine 67 False Pressed) == Right ClearBalls)
  check "q quits" (commandFor mine (keyboard mine 113 False Pressed) == Right QuitApp)
  check "uppercase Q quits" (commandFor mine (keyboard mine 81 False Pressed) == Right QuitApp)
  check "Escape quits" (commandFor mine (keyboard mine 27 False Pressed) == Right QuitApp)
  check "key repeat is ignored" (commandFor mine (keyboard mine 110 True Pressed) == Right NoChange)
  check "key release is ignored" (commandFor mine (keyboard mine 110 False Released) == Right NoChange)
  check "other window keys are ignored" (commandFor mine (keyboard other 110 False Pressed) == Right NoChange)
  check "close quits" (commandFor mine (WindowCloseEvent 0 mine) == Right QuitApp)
  check "other window close is ignored" (commandFor mine (WindowCloseEvent 0 other) == Right NoChange)
  check "global quit" (commandFor mine (QuitEvent 0) == Right QuitApp)
  check "target reset reports an error" (case commandFor mine (RenderTargetsResetEvent 0 mine) of Left _ => True; _ => False)
  check "device reset reports an error" (case commandFor mine (RenderDeviceResetEvent 0 mine) of Left _ => True; _ => False)
  check "other renderer reset is ignored" (commandFor mine (RenderDeviceResetEvent 0 other) == Right NoChange)

main : IO ()
main = do
  let initial = emptyScene 42
  check "starts empty" (initial.count == 0 && null initial.balls)
  let ten = applyCommand AddBalls initial
  let twenty = applyCommand AddBalls ten
  check "each press adds ten" (ten.count == 10 && length ten.balls == 10 && twenty.count == 20 && length twenty.balls == 20)
  let cleared = applyCommand ClearBalls twenty
  check "clear removes all balls and preserves random state" (cleared.count == 0 && null cleared.balls && cleared.seed == twenty.seed)
  check "repeated clear is safe" (null (applyCommand ClearBalls cleared).balls)
  check "add after clear starts another group of ten" ((applyCommand AddBalls cleared).count == 10)
  let sample = spawnMany 100 initial
  check "random positions and sizes fit the scene" (all inside sample.balls)
  check "random colors stay bright and in range" (all (\ball => let MkColor r g b a = ball.color
                                                                 in r >= 70 && g >= 70 && b >= 70 && a >= 90) sample.balls)
  check "random velocities fit the stated range" (all (\ball => let speed = sqrt (ball.vx * ball.vx + ball.vy * ball.vy)
                                                              in speed >= 80 && speed <= 220) sample.balls)
  check "random sample includes translucent balls" (any (\ball => ball.color.colorAlpha < 255) sample.balls)
  check "random sample includes opaque balls" (any (\ball => ball.color.colorAlpha == 255) sample.balls)
  check "same seed gives the same balls" (all id (zipWith sameBall ten.balls (applyCommand AddBalls initial).balls))
  check "new balls use new random values" (twenty.seed /= ten.seed)
  check "zero seed is usable" (all inside (applyCommand AddBalls (emptyScene 0)).balls)
  check "600 frames preserve bounds and count" (manySteps 600 (spawnMany 10 initial))
  physics
  controls
  putStrLn "Balls simulation and input tests passed"
