module WindowStyleTests

import SDL3
import SDL3.Scoped

%default covering

%foreign "C:idris_test_window_style, libidris2_sdl3_test, fixtures.h"
prim__styleMatches : Bits32 -> Int -> Int -> PrimIO Int

expect : IO Bool -> Bool -> IO (Either String ())
expect query expected = do
  actual <- query
  if actual == expected then pure (Right ()) else pure (Left "Window style query returned an incorrect state")

matchesSDL : Window -> IO Bool -> IO Bool -> IO (Either String ())
matchesSDL window borderQuery resizeQuery = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  bordered <- borderQuery
  resizable <- resizeQuery
  1 <- primIO (prim__styleMatches identifier (if bordered then 1 else 0) (if resizable then 1 else 0))
    | _ => pure (Left "Window style queries did not match SDL flags")
  pure (Right ())

changes : Window -> Window -> List (Bool, Bool) -> IO (Either String ())
changes window other [] = pure (Right ())
changes window other ((bordered, resizable) :: rest) = do
  True <- setWindowBordered window bordered | False => Left <$> getError
  True <- setWindowResizable window resizable | False => Left <$> getError
  -- The dummy driver accepts these requests without changing the flags.
  Right () <- matchesSDL window (isWindowBordered window) (isWindowResizable window) | Left err => pure (Left err)
  Right () <- expect (isWindowHidden window) True | Left err => pure (Left err)
  Right () <- expect (isWindowBordered other) False | Left err => pure (Left err)
  Right () <- expect (isWindowResizable other) True | Left err => pure (Left err)
  changes window other rest

cachedActions : Window -> IO (Either String ())
cachedActions window = do
  let borderQuery = isWindowBordered window
  let resizeQuery = isWindowResizable window
  let removeBorder = setWindowBordered window False
  let allowResize = setWindowResizable window True
  True <- removeBorder | False => Left <$> getError
  True <- allowResize | False => Left <$> getError
  Right () <- matchesSDL window borderQuery resizeQuery | Left err => pure (Left err)
  True <- setWindowBordered window True | False => Left <$> getError
  True <- setWindowResizable window False | False => Left <$> getError
  Right () <- matchesSDL window borderQuery resizeQuery | Left err => pure (Left err)
  True <- removeBorder | False => Left <$> getError
  True <- allowResize | False => Left <$> getError
  matchesSDL window borderQuery resizeQuery

programmaticResize : Window -> IO (Either String ())
programmaticResize window = do
  True <- setWindowResizable window False | False => Left <$> getError
  Right () <- expect (isWindowResizable window) False | Left err => pure (Left err)
  True <- setWindowSize window (MkSize 47 29) | False => Left <$> getError
  True <- syncWindow window | False => Left <$> getError
  Right (MkSize 47 29) <- getWindowSize window | _ => pure (Left "User-resizing policy prevented programmatic resizing")
  expect (isWindowResizable window) False

rendererState : Window -> Renderer -> IO (Either String ())
rendererState window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- setWindowBordered window True | False => Left <$> getError
    True <- setWindowResizable window True | False => Left <$> getError
    Right () <- matchesSDL window (isWindowBordered window) (isWindowResizable window) | Left err => pure (Left err)
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Changing window style altered texture dimensions")
    True <- setDrawColor renderer 20 180 60 255 | False => Left <$> getError
    True <- clear renderer | False => Left <$> getError
    pure (Right ())

export
windowStyleTests : IO (Either String ())
windowStyleTests = do
  copied <- withWindow "window style" 37 23 hidden $ \window =>
    withWindow "other style" 16 16 (hidden <+> borderless <+> resizable) $ \other => do
      bordered <- isWindowBordered window
      resizable <- isWindowResizable window
      Right identifier <- getWindowID window | Left err => pure (Left err)
      if not bordered || resizable then pure (Left "Default window style was incorrect") else do
        Right () <- changes window other [(False, False), (True, True), (True, True), (False, True), (True, False)]
          | Left err => pure (Left err)
        Right () <- cachedActions window | Left err => pure (Left err)
        Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Changing window style changed its size")
        Right () <- programmaticResize window | Left err => pure (Left err)
        Right () <- withRenderer window (rendererState window) | Left err => pure (Left err)
        Right after <- getWindowID window | Left err => pure (Left err)
        title <- getWindowTitle window
        if after /= identifier || title /= "window style" then pure (Left "Window style changes altered identity or title")
           else pure (Right (bordered, resizable))
  Right (True, False) <- pure copied | _ => pure (Left "Copied style state changed after window destruction")
  pure (Right ())
