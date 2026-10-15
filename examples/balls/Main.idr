module Main

import SDL3
import SDL3.Scoped
import SDL3.Mixer
import SDL3.TTF
import SDL3.TTF.Scoped

import Assets
import Simulation
import System

%default covering

record Display where
  constructor MkDisplay
  renderer : Renderer
  texture : Texture StreamingAccess
  panels : RectBuffer
  fpsText, countText, helpText : Text
  helpPosition : Point RenderSpace

record Context where
  constructor MkContext
  window : Window
  identifier : WindowID
  display : Display
  events : EventBuffer
  voices : List Track
  smoke : Bool

record Meter where
  constructor MkMeter
  since : Bits64
  frames : Bits64
  shown : Bits64

record State where
  constructor MkState
  scene : Scene
  available : List Track
  countX : Double
  meter : Meter
  previous : Bits64
  frameNumber : Bits64
  totalHits : Nat

pollCommands : Nat -> Context -> Scene -> IO (Either String (Maybe Scene))
pollCommands Z context scene = pure (Right (Just scene))
pollCommands (S n) context scene = do
  Just event <- pollEventData context.events | Nothing => pure (Right (Just scene))
  let Right command = commandFor context.identifier event | Left err => pure (Left err)
  case command of
    QuitApp => pure (Right Nothing)
    _ => pollCommands n context (applyCommand command scene)

drawBalls : Display -> List Ball -> IO Bool
drawBalls display [] = pure True
drawBalls display (ball :: rest) = do
  let MkColor r g b a = ball.color
  True <- setTextureColorMod display.texture r g b | False => pure False
  True <- setTextureAlphaMod display.texture a | False => pure False
  True <- renderTexture display.renderer display.texture
    (Just (MkFRect (ball.x - ball.radius) (ball.y - ball.radius) (2 * ball.radius) (2 * ball.radius)))
    | False => pure False
  drawBalls display rest

frame : Display -> Scene -> Double -> IO (Either String ())
frame display scene countX = do
  True <- setDrawColor display.renderer 8 12 26 255 | False => Left <$> getError
  True <- clear display.renderer | False => Left <$> getError
  True <- drawBalls display scene.balls | False => Left <$> getError
  -- Draw the text panels last so overlapping balls cannot hide the labels.
  True <- setDrawColor display.renderer 8 12 26 230 | False => Left <$> getError
  True <- fillRects display.renderer display.panels 2 | False => Left <$> getError
  True <- drawText display.fpsText (MkPoint 14 12) | False => Left <$> getError
  True <- drawText display.countText (MkPoint countX 12) | False => Left <$> getError
  True <- drawText display.helpText display.helpPosition | False => Left <$> getError
  True <- present display.renderer | False => Left <$> getError
  pure (Right ())

countPosition : Text -> IO (Either String Double)
countPosition label = do
  Right (MkSize width _) <- getTextSize label | Left err => pure (Left err)
  pure (Right (786 - cast width))

updateCount : Display -> Nat -> Nat -> Double -> IO (Either String Double)
updateCount display old new x = if old == new then pure (Right x) else do
  True <- setTextString display.countText ("Balls: " ++ show new) | False => Left <$> getError
  countPosition display.countText

updateFPS : Display -> Bits64 -> Meter -> IO (Either String Meter)
updateFPS display now meter =
  if now - meter.since < 500000000 then pure (Right meter) else do
    -- Count completed frames, including their rendering and pacing time.
    let elapsed = now - meter.since
    let fps = (meter.frames * 1000000000 + elapsed `div` 2) `div` elapsed
    True <- (if fps == meter.shown then pure True else setTextString display.fpsText ("FPS: " ++ show fps))
      | False => Left <$> getError
    pure (Right (MkMeter now 0 fps))

-- Smoke mode starts empty too. Exercise add, clear, both resize directions,
-- wall sounds, and text updates without a keyboard or display device.
smokeCommand : Bits64 -> Command
smokeCommand 1 = AddBalls
smokeCommand 2 = AddBalls
smokeCommand 90 = ClearBalls
smokeCommand _ = NoChange

smokeResize : Context -> Bits64 -> IO Bool
smokeResize context 45 = setWindowSize context.window (MkSize 1000 700)
smokeResize context 75 = setWindowSize context.window (MkSize 800 600)
smokeResize _ _ = pure True

loop : Context -> State -> IO (Either String ())
loop context state =
  if context.smoke && state.frameNumber == 120 then do
    if state.scene.count /= 0 || state.totalHits == 0
      then pure (Left "Balls smoke test did not clear the scene or play a wall sound")
      else do
        putStrLn ("Balls smoke passed: 120 frames, 0 -> 10 -> 20 -> 0 balls, " ++ show state.totalHits ++ " wall hits.")
        pure (Right ())
  else do
    start <- ticksNS
    Right (Just input) <- pollCommands 128 context state.scene
      | Right Nothing => pure (Right ())
      | Left err => pure (Left err)
    True <- (if context.smoke then smokeResize context state.frameNumber else pure True)
      | False => Left <$> getError
    let edited = if context.smoke then applyCommand (smokeCommand state.frameNumber) input else input
    -- Ignore time beyond 100 ms after a stall. Do not run a long catch-up loop.
    let (scene, hits) = advance (cast (start - state.previous) / 1000000000) edited
    Right available <- playBounces context.voices state.available hits | Left err => pure (Left err)
    Right x <- updateCount context.display state.scene.count scene.count state.countX | Left err => pure (Left err)
    Right meter <- updateFPS context.display start state.meter | Left err => pure (Left err)
    Right () <- frame context.display scene x | Left err => pure (Left err)
    end <- ticksNS
    -- Round the 60 Hz budget up. Slow frames do not underflow or trigger catch-up frames.
    delayNS (frameDelay (end - start))
    loop context (MkState scene available x ({ frames := meter.frames + 1 } meter)
                          start (state.frameNumber + 1) (state.totalHits + hits))

withLabel : RendererTextEngine -> Font -> String -> (Text -> IO (Either String a)) -> IO (Either String a)
withLabel engine font value action = withText engine font value $ \label => do
  True <- setTextColor label 238 243 255 255 | False => Left <$> getError
  action label

runWindow : Window -> List Track -> Bool -> IO (Either String ())
runWindow window voices smoke = withRenderer window $ \renderer => do
  Right identifier <- getWindowID window | Left err => pure (Left err)
  True <- setRenderLogicalPresentation renderer 800 600 PresentationLetterbox | False => Left <$> getError
  True <- setDrawBlendMode renderer AlphaBlend | False => Left <$> getError
  disabled <- setRenderVSync renderer VSyncDisabled
  case disabled of
    True => pure ()
    False => do
      err <- getError
      putStrLn ("Cannot disable VSync. The frame rate can be lower than 60: " ++ err)
  withBallTexture renderer $ \texture => withRectBuffer 2 $ \panels => do
    True <- setRect panels 0 (MkFRect 0 0 800 48) | False => Left <$> getError
    True <- setRect panels 1 (MkFRect 0 552 800 48) | False => Left <$> getError
    withFont "assets/Lato-Regular.ttf" 22 $ \font => withRendererTextEngine renderer $ \engine =>
      withLabel engine font "FPS: --" $ \fpsText =>
        withLabel engine font "Balls: 0" $ \countText =>
          withLabel engine font "n: add 10 balls     c: clear     q / Esc: quit" $ \helpText => do
            Right (MkSize width height) <- getTextSize helpText | Left err => pure (Left err)
            Right x <- countPosition countText | Left err => pure (Left err)
            withEventBuffer $ \events => do
              seed <- if smoke then pure 42 else performanceCounter
              now <- ticksNS
              let display = MkDisplay renderer texture panels fpsText countText helpText
                                      (MkPoint ((800 - cast width) / 2) (588 - cast height))
              let context = MkContext window identifier display events voices smoke
              loop context (MkState (emptyScene seed) voices x (MkMeter now 0 0) now 0 0)

run : Bool -> IO (Either String ())
run smoke = withTTF $ withSounds $ \voices =>
  withWindow "Bouncing balls" 800 600 resizable $ \window => runWindow window voices smoke

main : IO ()
main = do
  args <- getArgs
  smoke <- case args of
    [_] => pure False
    [_, "--smoke"] => pure True
    _ => die "Usage: balls [--smoke]"
  ok <- init video
  result <- if ok then run smoke else Left <$> getError
  quit
  either die pure result
