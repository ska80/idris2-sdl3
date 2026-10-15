module Main

import SDL3
import SDL3.Scoped
import SDL3.Image.Scoped
import SDL3.TTF
import SDL3.TTF.Scoped

import System

%default covering

stopRequested : WindowID -> EventBuffer -> IO Bool
stopRequested identifier events = do
  event <- pollEventData events
  case event of
    Nothing => pure False
    Just (QuitEvent _) => pure True
    Just (WindowCloseEvent _ target) =>
      if target == identifier then pure True else stopRequested identifier events
    Just (KeyboardEvent _ (MkKeyboardData target Pressed _ key _ False)) =>
      if target == identifier && key == escapeKey then pure True else stopRequested identifier events
    _ => stopRequested identifier events

frame : Renderer -> Texture StaticAccess -> Text -> IO (Either String ())
frame renderer image label = do
  True <- setDrawColor renderer 20 24 32 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- renderTexture renderer image (Just (MkFRect 32 32 256 256)) | False => Left <$> getError
  True <- drawText label (MkPoint 32 320) | False => Left <$> getError
  True <- present renderer | False => Left <$> getError
  pure (Right ())

loop : WindowID -> Renderer -> Texture StaticAccess -> Text -> EventBuffer -> Bits64 -> Maybe Nat -> IO (Either String ())
loop identifier renderer image label events previous (Just Z) = pure (Right ())
loop identifier renderer image label events previous budget = do
  stop <- stopRequested identifier events
  case stop of
    True => pure (Right ())
    False => do
      now <- (`div` 1000) <$> ticks
      case now /= previous of
        True => do
          True <- setTextString label ("Reusable UTF-8 text: café. SDL time: " ++ show now ++ " seconds.")
            | False => Left <$> getError
          drawNext now
        False => drawNext now
  where
    drawNext : Bits64 -> IO (Either String ())
    drawNext now = do
      Right () <- frame renderer image label | Left err => pure (Left err)
      delay 16
      let next = case budget of
            Nothing => Nothing
            Just (S n) => Just n
            Just Z => Just Z
      loop identifier renderer image label events now next

run : String -> String -> Maybe Nat -> IO (Either String ())
run imagePath fontPath budget = withTTF $
  withWindow "Image and reusable text - Escape to close" 640 480 resizable $ \window =>
    withRenderer window $ \renderer => do
      Right identifier <- getWindowID window | Left err => pure (Left err)
      True <- setRenderLogicalPresentation renderer 640 480 PresentationLetterbox | False => Left <$> getError
      withTexture renderer imagePath $ \image => withFont fontPath 24 $ \font =>
        withRendererTextEngine renderer $ \engine =>
          withText engine font "Reusable UTF-8 text: café. Escape closes this window." $ \label => do
            True <- setTextWrapWidth label 576 | False => Left <$> getError
            True <- setTextColor label 240 220 160 255 | False => Left <$> getError
            Right (MkSize width height) <- getTextSize label | Left err => pure (Left err)
            putStrLn ("Initial text pixels: " ++ show width ++ " x " ++ show height)
            withEventBuffer $ \events => loop identifier renderer image label events 0 budget

main : IO ()
main = do
  args <- getArgs
  case args of
    _ :: imagePath :: fontPath :: rest => do
      True <- init video | False => do
        err <- getError
        quit
        putStrLn err
        exitFailure
      result <- run imagePath fontPath (if elem "--smoke" rest then Just 3 else Nothing)
      quit
      case result of
        Right () => pure ()
        Left err => do
          putStrLn err
          exitFailure
    _ => do
      putStrLn "Usage: media IMAGE FONT [--smoke]"
      exitFailure
