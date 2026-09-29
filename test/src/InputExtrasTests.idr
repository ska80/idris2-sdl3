module InputExtrasTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_subset_event, libidris2_sdl3_test, subset_fixtures.h"
prim__event : Int -> PrimIO Int

matchesDrop : DropData -> String -> Bool
matchesDrop value text = value.windowID == MkWindowID 0xffffffff &&
                        value.x == -12.5 && value.y == 100.25 &&
                        value.source == "source Ω" && value.text == text

matches : Int -> Event -> Bool
matches 0 (GamepadAddedEvent 0x100000002 (MkGamepadID 0x80000001)) = True
matches 1 (GamepadRemovedEvent 0x100000002 (MkGamepadID 0x80000001)) = True
matches 2 (GamepadRemappedEvent 0x100000002 (MkGamepadID 0x80000001)) = True
matches 3 (GamepadAxisEvent 0x100000002 (MkGamepadAxisData (MkGamepadID 0x80000001) (MkGamepadAxis 255) (-32768))) = True
matches 4 (GamepadButtonEvent 0x100000002 (MkGamepadButtonData (MkGamepadID 0x80000001) (MkGamepadButton 255) Pressed)) = True
matches 5 (GamepadButtonEvent 0x100000002 (MkGamepadButtonData (MkGamepadID 0x80000001) (MkGamepadButton 255) Released)) = True
matches 6 (DropFileEvent 0x100000002 value) = matchesDrop value "/tmp/雪 file.wav"
matches 7 (DropTextEvent 0x100000002 value) = matchesDrop value "drop λ text"
matches 8 (DropBeginEvent 0x100000002 (MkWindowID 0xffffffff)) = True
matches 9 (DropCompleteEvent 0x100000002 (MkWindowID 0xffffffff)) = True
matches 10 (DropPositionEvent 0x100000002 value) = matchesDrop value ""
matches _ _ = False

typeMatches : Int -> EventType -> Bool
typeMatches 0 GamepadAdded = True
typeMatches 1 GamepadRemoved = True
typeMatches 2 GamepadRemapped = True
typeMatches 3 GamepadAxisMotion = True
typeMatches 4 GamepadButtonDown = True
typeMatches 5 GamepadButtonUp = True
typeMatches 6 DropFile = True
typeMatches 7 DropText = True
typeMatches 8 DropBegin = True
typeMatches 9 DropComplete = True
typeMatches 10 DropPosition = True
typeMatches _ _ = False

pollData : Nat -> EventBuffer -> IO (Maybe Event)
pollData Z buffer = pure Nothing
pollData (S n) buffer = do
  Nothing <- pollEventData buffer | Just event => pure (Just event)
  pollData n buffer

pollType : Nat -> EventBuffer -> IO (Maybe EventType)
pollType Z buffer = pure Nothing
pollType (S n) buffer = do
  Nothing <- pollEvent buffer | Just event => pure (Just event)
  pollType n buffer

events : EventBuffer -> List Int -> IO (Either String (List (Int, Event)))
events buffer [] = pure (Right [])
events buffer (kind :: rest) = do
  1 <- primIO (prim__event kind) | _ => Left <$> getError
  Just event <- pollData 16 buffer | Nothing => pure (Left "Missing subset payload event")
  True <- pure (matches kind event) | False => pure (Left "Subset event payload was incorrect")
  1 <- primIO (prim__event kind) | _ => Left <$> getError
  Just typ <- pollType 16 buffer | Nothing => pure (Left "Missing subset type event")
  True <- pure (typeMatches kind typ) | False => pure (Left "Subset event type was incorrect")
  1 <- primIO (prim__event kind) | _ => Left <$> getError
  Right (Just timed) <- waitEventDataTimeout buffer 100 | _ => pure (Left "Missing timed subset event")
  True <- pure (matches kind timed) | False => pure (Left "Timed subset payload was incorrect")
  1 <- primIO (prim__event kind) | _ => Left <$> getError
  Right waited <- waitEventData buffer | Left err => pure (Left err)
  True <- pure (matches kind waited) | False => pure (Left "Waited subset payload was incorrect")
  Right tail <- events buffer rest | Left err => pure (Left err)
  pure (Right ((kind, event) :: tail))

clipboard : IO (Either String ())
clipboard = do
  True <- setClipboardText "copy 雪 λ" | False => Left <$> getError
  True <- hasClipboardText | False => pure (Left "Clipboard text was not available")
  Right copied <- getClipboardText | Left err => pure (Left err)
  True <- setClipboardText "" | False => Left <$> getError
  False <- hasClipboardText | True => pure (Left "Empty clipboard still reported text")
  Right "" <- getClipboardText | _ => pure (Left "Empty clipboard was treated as failure")
  if copied == "copy 雪 λ" then pure (Right ()) else pure (Left "Copied clipboard text changed")

mouse : Window -> IO (Either String ())
mouse window = do
  enabled <- setWindowRelativeMouseMode window True
  case enabled of
    False => do
      err <- getError
      if err == "" then pure (Left "Relative mouse failure lost its error") else finish
    True => do
      True <- getWindowRelativeMouseMode window | False => pure (Left "Relative mode query lost state")
      finish
  where
    finish : IO (Either String ())
    finish = do
      True <- setWindowRelativeMouseMode window False | False => Left <$> getError
      False <- getWindowRelativeMouseMode window | True => pure (Left "Relative mode did not disable")
      True <- hideCursor | False => Left <$> getError
      False <- cursorVisible | True => pure (Left "Cursor did not hide")
      True <- showCursor | False => Left <$> getError
      True <- cursorVisible | False => pure (Left "Cursor did not show")
      _ <- captureMouse False
      cursor <- createSystemCursor PointerCursor
      case cursor of
        Left err => if err == "" then pure (Left "Cursor failure lost its error") else pure (Right ())
        Right value => do
          selected <- setCursor (Just value)
          restored <- setCursor Nothing
          destroyCursor value
          if selected && restored then pure (Right ()) else pure (Left "Cursor selection failed")

cursorScope : IO (Either String ())
cursorScope = do
  called <- newIORef False
  result <- withSystemCursor CrosshairCursor $ \cursor => do
    writeIORef called True
    True <- setCursor (Just cursor) | False => Left <$> getError
    True <- setCursor Nothing | False => Left <$> getError
    pure (Right (the Bits64 0x100000002))
  ran <- readIORef called
  case result of
    Right 0x100000002 => if ran then pure (Right ()) else pure (Left "Cursor scope skipped a successful callback")
    Right _ => pure (Left "Cursor scope changed callback result")
    Left err => if not ran && err /= "" then pure (Right ()) else pure (Left err)

export
inputExtrasTests : IO (Either String ())
inputExtrasTests = do
  Right () <- cursorScope | Left err => pure (Left err)
  Right () <- clipboard | Left err => pure (Left err)
  Right () <- withWindow "mouse subset" 32 32 hidden mouse | Left err => pure (Left err)
  Right copied <- withEventBuffer (\buffer => events buffer [0,1,2,3,4,5,6,7,8,9,10]) | Left err => pure (Left err)
  if all (\(kind, event) => matches kind event) copied then pure (Right ())
    else pure (Left "Copied events changed after buffer cleanup")
