module Main

import SDL3
import SDL3.Scoped
import SDL3.Raw
import SDL3.TTF
import SDL3.TTF.Scoped

import Data.IORef

import System

%default covering

%foreign "C:idris_test_font_path, libidris2_sdl3_ttf_test, fixtures.h"
prim__fontPath : PrimIO String

failing "Mismatch between"
  textureAsText : Texture StaticAccess -> IO (Either String (Size PixelUnits))
  textureAsText texture = getTextSize texture

failing "Mismatch between"
  fontAsEngine : Font -> Font -> IO (Either String Text)
  fontAsEngine font other = createText font other "wrong"

failing "Mismatch between"
  windowPointAsTextPosition : Text -> Point WindowSpace -> IO Bool
  windowPointAsTextPosition = drawText

failing "Name SDL3.TTF.MkFont is private"
  forgeFont : AnyPtr -> Font
  forgeFont = MkFont

failing "Name SDL3.TTF.MkText is private"
  forgeText : AnyPtr -> NativeSize -> Text
  forgeText = MkText

failing "Name SDL3.TTF.MkRendererTextEngine is private"
  forgeEngine : AnyPtr -> RendererTextEngine
  forgeEngine = MkRendererTextEngine

textTests : Text -> IO (Either String (Size PixelUnits))
textTests text = do
  let measure = getTextSize text
  Right initial <- measure | Left err => pure (Left err)
  True <- pure (initial.width > 0 && initial.height > 0) | False => pure (Left "Initial text was empty")
  True <- setTextString text "WWWWWWWWWWWWWW" | False => Left <$> getError
  Right longer <- measure | Left err => pure (Left err)
  True <- pure (longer.width > initial.width) | False => pure (Left "Cached measurement did not read changed text")
  True <- setTextString text "one two three four five" | False => Left <$> getError
  True <- setTextWrapWidth text 40 | False => Left <$> getError
  Right wrapped <- measure | Left err => pure (Left err)
  True <- pure (wrapped.height > initial.height) | False => pure (Left "Text did not wrap")
  False <- setTextWrapWidth text 0x80000000 | True => pure (Left "Oversized wrap accepted")
  True <- setTextColor text 255 128 0 255 | False => Left <$> getError
  True <- drawText text (MkPoint 2.5 3.5) | False => Left <$> getError
  True <- setTextWrapWidth text 0 | False => Left <$> getError
  True <- setTextString text "λ café" | False => Left <$> getError
  True <- drawText text (MkPoint 2 70) | False => Left <$> getError
  True <- setTextString text "" | False => Left <$> getError
  Right empty <- measure | Left err => pure (Left err)
  True <- pure (empty.width == 0) | False => pure (Left "Empty text retained old width")
  pure (Right initial)

failureTests : String -> IO (Either String ())
failureTests path = do
  called <- newIORef False
  Left _ <- withFont path 0 (\font => do writeIORef called True; pure (Right ()))
    | Right () => pure (Left "Zero-size font loaded")
  False <- readIORef called | True => pure (Left "Failed font creation ran callback")
  Left _ <- openFont "/nonexistent/idris-font.ttf" 18 | Right font => do
    closeFont font
    pure (Left "Missing font loaded")
  pure (Right ())

run : String -> IO (Either String (Size PixelUnits))
run path = withTTF $ withWindow "TTF tests" 128 128 hidden $ \window => withRenderer window $ \renderer =>
  withFont path 18 $ \font => withRendererTextEngine renderer $ \engine => do
    Right size <- withText engine font "Hello" textTests | Left err => pure (Left err)
    result <- withText engine font "cleanup" (\text => pure (the (Either String ()) (Left "text callback")))
    Left "text callback" <- pure result | _ => pure (Left "Text scope changed callback error")
    Right () <- failureTests path | Left err => pure (Left err)
    pure (Right size)

main : IO ()
main = do
  path <- primIO prim__fontPath
  False <- pure (path == "") | True => die "Set SDL3_TEST_FONT to a TrueType font or install DejaVu Sans"
  True <- SDL3.init video | False => do
    getError >>= putStrLn
    SDL3.quit
    exitFailure
  result <- run path
  SDL3.quit
  case result of
    Right size => if size.width > 0 then putStrLn "TTF Idris tests passed" else die "Copied text size was lost"
    Left err => die err
