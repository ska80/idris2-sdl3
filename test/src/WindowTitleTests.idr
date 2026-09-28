module WindowTitleTests

import SDL3
import SDL3.Scoped
import Data.List

%default covering

expect : IO String -> String -> IO (Either String ())
expect query expected = do
  actual <- query
  if actual == expected then pure (Right ()) else pure (Left "Window title did not match the supplied text")

changes : Window -> Window -> IO (Either String String)
changes window other = do
  let query = getWindowTitle window
  Right () <- expect query "initial title" | Left err => pure (Left err)
  original <- query
  Right identifier <- getWindowID window | Left err => pure (Left err)
  True <- setWindowTitle window "SDL λ 窗口 🐢 é" | False => Left <$> getError
  Right () <- expect query "SDL λ 窗口 🐢 é" | Left err => pure (Left err)
  copied <- query
  True <- setWindowTitle window "" | False => Left <$> getError
  Right () <- expect query "" | Left err => pure (Left err)
  let longTitle = concat (replicate 512 "SDL λ ")
  True <- setWindowTitle window longTitle | False => Left <$> getError
  Right () <- expect query longTitle | Left err => pure (Left err)
  True <- setWindowTitle window longTitle | False => Left <$> getError
  Right () <- expect query longTitle | Left err => pure (Left err)
  Right () <- expect (getWindowTitle other) "other title" | Left err => pure (Left err)
  Right after <- getWindowID window | Left err => pure (Left err)
  if after /= identifier || original /= "initial title"
     then pure (Left "A title change altered window identity or an earlier copy")
     else pure (Right copied)

rendererState : Window -> Renderer -> IO (Either String ())
rendererState window renderer = withTargetTexture renderer 7 9 $ \texture =>
  withRenderTarget renderer (Just texture) $ do
    True <- setRenderLogicalPresentation renderer 4 3 PresentationStretch | False => Left <$> getError
    True <- setWindowTitle window "title with a renderer" | False => Left <$> getError
    Right () <- expect (getWindowTitle window) "title with a renderer" | Left err => pure (Left err)
    Right (MkSize 37 23) <- getWindowSize window | _ => pure (Left "Changing the title altered window dimensions")
    Right (MkSize 7 9) <- getTextureSize texture | _ => pure (Left "Changing the title altered texture dimensions")
    pure (Right ())

export
windowTitleTests : IO (Either String ())
windowTitleTests = do
  copied <- withWindow "initial title" 37 23 hidden $ \window =>
    withWindow "other title" 16 16 hidden $ \other => do
      Right saved <- changes window other | Left err => pure (Left err)
      Right () <- withRenderer window (rendererState window) | Left err => pure (Left err)
      Right () <- expect (getWindowTitle other) "other title" | Left err => pure (Left err)
      pure (Right saved)
  Right saved <- pure copied | Left err => pure (Left err)
  -- All windows, the renderer, and the target are gone. Only the string copy remains.
  expect (pure saved) "SDL λ 窗口 🐢 é"
