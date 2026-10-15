module Main

import SDL3
import SDL3.Scoped
import SDL3.Image.Scoped
import SDL3.TTF
import SDL3.TTF.Scoped

import System

%default covering

data Next = KeepWaiting | Redraw | Stop

eventAction : WindowID -> Maybe Event -> Either String Next
eventAction _ Nothing = Right KeepWaiting
eventAction identifier (Just event) = case event of
  QuitEvent _ => Right Stop
  WindowCloseEvent _ target => forWindow target Stop
  KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False) =>
    if key == escapeKey then forWindow target Stop else Right KeepWaiting
  WindowShownEvent _ target => forWindow target Redraw
  WindowExposedEvent _ target => forWindow target Redraw
  WindowRestoredEvent _ target => forWindow target Redraw
  WindowResizedEvent _ (MkWindowSizeData target _ _) => forWindow target Redraw
  WindowPixelSizeChangedEvent _ (MkPixelSizeData target _ _) => forWindow target Redraw
  WindowDisplayScaleChangedEvent _ target => forWindow target Redraw
  RenderTargetsResetEvent _ target => reset target
  RenderDeviceResetEvent _ target => reset target
  _ => Right KeepWaiting
  where
    forWindow : WindowID -> Next -> Either String Next
    forWindow target action = Right (if target == identifier then action else KeepWaiting)

    reset : WindowID -> Either String Next
    reset target = if target == identifier
      then Left "Renderer reset. Restart the example to recreate the image and text resources."
      else Right KeepWaiting

statusText : Bits64 -> String
statusText seconds = "Reusable UTF-8 text: café. SDL time: " ++ show seconds ++ " seconds."

frame : Renderer -> Texture StaticAccess -> Text -> IO (Either String ())
frame renderer image label = do
  True <- setDrawColor renderer 20 24 32 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer image (Just (MkFRect 32 32 256 256)) | False => Left <$> getError
  True <- drawText label (MkPoint 32 320) | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  pure (Right ())

loop : WindowID -> Renderer -> Texture StaticAccess -> Text -> EventBuffer ->
       Bits64 -> Bool -> Maybe Nat -> IO (Either String ())
loop _ _ _ _ _ _ _ (Just Z) = pure (Right ())
loop identifier renderer image label events previous redraw budget = do
  -- Handle pending close/reset events before using the renderer or its textures.
  pending <- pollEventData events
  case pending of
    Just _ => react pending
    Nothing => do
      now <- ticks
      let seconds = now `div` 1000
      case redraw || seconds /= previous of
        True => do
          True <- (if seconds == previous then pure True else setTextString label (statusText seconds))
            | False => Left <$> getError
          drawNext seconds
        False => do
          -- Wait for input or the next clock update. Do not redraw unchanged content.
          Right event <- waitEventDataTimeout events (cast (1000 - now `mod` 1000))
            | Left err => pure (Left err)
          react event
  where
    react : Maybe Event -> IO (Either String ())
    react event = do
      let Right action = eventAction identifier event | Left err => pure (Left err)
      case action of
        Stop => pure (Right ())
        Redraw => loop identifier renderer image label events previous True budget
        KeepWaiting => loop identifier renderer image label events previous redraw budget

    drawNext : Bits64 -> IO (Either String ())
    drawNext seconds = do
      Right () <- frame renderer image label | Left err => pure (Left err)
      -- Smoke mode draws three frames without waiting for clock updates.
      case budget of
        Nothing => loop identifier renderer image label events seconds False Nothing
        Just (S n) => loop identifier renderer image label events seconds True (Just n)
        Just Z => pure (Right ())

run : String -> String -> Maybe Nat -> IO (Either String ())
run imagePath fontPath budget = withTTF $
  withWindow "Image and reusable text - Escape to close" 640 480 resizable $ \window =>
    withRenderer window $ \renderer => do
      Right identifier <- getWindowID window | Left err => pure (Left err)
      True <- setRenderLogicalPresentation renderer 640 480 PresentationLetterbox | False => Left <$> getError
      withTexture renderer imagePath $ \image => withFont fontPath 24 $ \font =>
        withRendererTextEngine renderer $ \engine => do
          seconds <- (`div` 1000) <$> ticks
          withText engine font (statusText seconds) $ \label => do
            True <- setTextWrapWidth label 576 | False => Left <$> getError
            True <- setTextColor label 240 220 160 255 | False => Left <$> getError
            Right (MkSize width height) <- getTextSize label | Left err => pure (Left err)
            putStrLn ("Initial text pixels: " ++ show width ++ " x " ++ show height)
            withEventBuffer $ \events => loop identifier renderer image label events seconds True budget

main : IO ()
main = do
  args <- getArgs
  options <- the (IO (String, String, Maybe Nat)) $ case args of
    [_, imagePath, fontPath] => pure (imagePath, fontPath, Nothing)
    [_, imagePath, fontPath, "--smoke"] => pure (imagePath, fontPath, Just 3)
    _ => die "Usage: media IMAGE FONT [--smoke]"
  let (imagePath, fontPath, budget) = options
  ok <- init video
  result <- if ok then run imagePath fontPath budget else Left <$> getError
  quit
  either die pure result
