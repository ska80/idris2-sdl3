module GamepadTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_attach_gamepad, libidris2_sdl3_test, subset_fixtures.h"
prim__attach : PrimIO Bits32
%foreign "C:idris_test_detach_gamepad, libidris2_sdl3_test, subset_fixtures.h"
prim__detach : Bits32 -> PrimIO Int
%foreign "C:idris_test_gamepad_input, libidris2_sdl3_test, subset_fixtures.h"
prim__input : Int16 -> Int -> PrimIO Int
%foreign "C:idris_test_gamepad_rumble, libidris2_sdl3_test, subset_fixtures.h"
prim__rumble : PrimIO Bits32

exercise : GamepadID -> Gamepad -> IO (Either String String)
exercise identifier@(MkGamepadID raw) pad = do
  Right ids <- listGamepads | Left err => pure (Left err)
  True <- pure (elem identifier ids) | False => pure (Left "Virtual gamepad was not listed")
  Right actual <- getGamepadID pad | Left err => pure (Left err)
  True <- pure (actual == identifier) | False => pure (Left "Gamepad identifier changed")
  Right name <- getGamepadName pad | Left err => pure (Left err)
  True <- gamepadConnected pad | False => pure (Left "New gamepad was disconnected")
  Right () <- withGamepad identifier (\second => do
    True <- gamepadConnected second | False => pure (Left "Second reference was disconnected")
    pure (Right ())) | Left err => pure (Left err)
  True <- gamepadConnected pad | False => pure (Left "Closing a second reference closed the first")
  let axisAction = getGamepadAxis pad leftStickX
  1 <- primIO (prim__input (-32768) 1) | _ => Left <$> getError
  updateGamepads
  -32768 <- axisAction | _ => pure (Left "Negative axis value did not survive FFI")
  True <- getGamepadButton pad gamepadSouth | False => pure (Left "Pressed button was not reported")
  1 <- primIO (prim__input 32767 0) | _ => Left <$> getError
  32767 <- axisAction | _ => pure (Left "Cached axis action did not read current state")
  False <- getGamepadButton pad gamepadSouth | True => pure (Left "Released button stayed pressed")
  True <- rumbleGamepad pad 65535 32768 1000 | False => Left <$> getError
  0xffff8000 <- primIO prim__rumble | _ => pure (Left "Rumble intensities changed")
  True <- rumbleGamepad pad 0 0 0 | False => Left <$> getError
  0 <- primIO prim__rumble | _ => pure (Left "Rumble did not stop")
  1 <- primIO (prim__detach raw) | _ => Left <$> getError
  False <- gamepadConnected pad | True => pure (Left "Removed gamepad stayed connected")
  pure (Right name)

export
gamepadTests : IO (Either String ())
gamepadTests = do
  called <- newIORef False
  Left _ <- withGamepad (MkGamepadID 0) (\pad => do
    writeIORef called True
    pure (Right ())) | Right () => pure (Left "Invalid gamepad opened")
  False <- readIORef called | True => pure (Left "Failed gamepad acquisition ran callback")
  raw <- primIO prim__attach
  if raw == 0 then Left <$> getError else do
    result <- withGamepad (MkGamepadID raw) (exercise (MkGamepadID raw))
    _ <- primIO (prim__detach raw)
    Right name <- pure result | Left err => pure (Left err)
    if name == "Idris virtual gamepad" then pure (Right ()) else pure (Left "Copied gamepad name changed")
