module ScalingTests

import SDL3

%default covering

%foreign "C:idris_test_pixel, libidris2_sdl3_test, fixtures.h"
prim__pixel : Bits32 -> Int -> Int -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> PrimIO Int

pixel : Bits32 -> (Int, Int) -> Bool -> IO Bool
pixel window (x, y) red =
  (== 1) <$> primIO (prim__pixel window x y (if red then 200 else 0) 0 0 255)

paint : Renderer -> FRect -> IO (Either String ())
paint renderer (MkFRect x y width height) = do
  True <- setDrawColor renderer 0 0 0 255 | False => Left <$> getError
  True <- clear renderer | False => Left <$> getError
  True <- setDrawColor renderer 200 0 0 255 | False => Left <$> getError
  True <- fillRect renderer x y width height | False => Left <$> getError
  pure (Right ())

logicalCase : Bits32 -> Renderer -> Int32 -> Int32 -> LogicalPresentation ->
              FRect -> (Int, Int) -> (Int, Int) -> IO (Either String ())
logicalCase window renderer width height mode rect inside outside = do
  True <- setRenderLogicalPresentation renderer width height mode | False => Left <$> getError
  Right () <- paint renderer rect | Left err => pure (Left err)
  -- Disable the logical transform before reading physical target coordinates.
  True <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled | False => Left <$> getError
  True <- pixel window inside True | False => pure (Left "Logical presentation misplaced the drawing")
  True <- pixel window outside False | False => pure (Left "Logical presentation drew outside the expected area")
  pure (Right ())

logicalCases : Bits32 -> Renderer -> IO (Either String ())
logicalCases window renderer = do
  Right () <- logicalCase window renderer 32 32 PresentationStretch (MkFRect 0 0 8 8) (12, 12) (20, 20)
    | Left err => pure (Left err)
  Right () <- logicalCase window renderer 32 16 PresentationLetterbox (MkFRect 0 0 32 16) (32, 24) (32, 8)
    | Left err => pure (Left err)
  Right () <- logicalCase window renderer 32 16 PresentationOverscan (MkFRect 8 0 8 16) (16, 32) (48, 32)
    | Left err => pure (Left err)
  Right () <- logicalCase window renderer 20 20 PresentationIntegerScale (MkFRect 0 0 20 20) (3, 3) (1, 1)
    | Left err => pure (Left err)
  logicalCase window renderer 0 0 PresentationDisabled (MkFRect 0 0 8 8) (4, 4) (12, 12)

scalePixels : Bits32 -> Renderer -> IO (Either String ())
scalePixels window renderer = do
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 8 8) | Left err => pure (Left err)
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  True <- pixel window (12, 20) True | False => pure (Left "Drawing scale was incorrect")
  True <- pixel window (20, 20) False | False => pure (Left "Horizontal scale was incorrect")
  True <- pixel window (12, 28) False | False => pure (Left "Vertical scale was incorrect")
  pure (Right ())

targetScale : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
targetScale window renderer texture = do
  True <- setRenderScale renderer 2 3 | False => Left <$> getError
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 4 4) | Left err => pure (Left err)
  True <- pixel window (2, 2) True | False => pure (Left "Texture target drawing was missing")
  True <- pixel window (6, 6) False | False => pure (Left "Texture target inherited window scale")
  True <- setRenderScale renderer 4 4 | False => Left <$> getError
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 8 8) | Left err => pure (Left err)
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  True <- pixel window (12, 20) True | False => pure (Left "Window scale was not restored")
  True <- pixel window (20, 20) False | False => pure (Left "Window inherited texture scale")
  pure (Right ())

retainedScale : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
retainedScale window renderer texture = do
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 2 2) | Left err => pure (Left err)
  True <- setRenderScale renderer 1 1 | False => Left <$> getError
  True <- pixel window (6, 6) True | False => pure (Left "Texture scale was not retained")
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  pure (Right ())

targetLogical : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
targetLogical window renderer texture = do
  True <- setRenderLogicalPresentation renderer 32 32 PresentationStretch | False => Left <$> getError
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 4 4) | Left err => pure (Left err)
  True <- pixel window (2, 2) True | False => pure (Left "Texture inherited window logical resolution")
  True <- setRenderLogicalPresentation renderer 8 8 PresentationStretch | False => Left <$> getError
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 8 8) | Left err => pure (Left err)
  True <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled | False => Left <$> getError
  True <- pixel window (12, 12) True | False => pure (Left "Window logical resolution was not restored")
  True <- pixel window (20, 20) False | False => pure (Left "Window inherited texture logical resolution")
  pure (Right ())

retainedLogical : Bits32 -> Renderer -> Texture TargetAccess -> IO (Either String ())
retainedLogical window renderer texture = do
  True <- setRenderTarget renderer (Just texture) | False => Left <$> getError
  Right () <- paint renderer (MkFRect 0 0 4 4) | Left err => pure (Left err)
  True <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled | False => Left <$> getError
  True <- pixel window (6, 6) True | False => pure (Left "Texture logical resolution was not retained")
  True <- pixel window (10, 10) False | False => pure (Left "Texture logical resolution scaled too far")
  True <- setRenderTarget renderer Nothing | False => Left <$> getError
  pure (Right ())

export
scalingTests : Window -> Renderer -> IO (Either String ())
scalingTests window renderer = do
  Right (MkWindowID identifier) <- getWindowID window | Left err => pure (Left err)
  Right texture <- createTargetTexture renderer 16 16 | Left err => pure (Left err)
  result <- do
    Right () <- logicalCases identifier renderer | Left err => pure (Left err)
    Right () <- scalePixels identifier renderer | Left err => pure (Left err)
    Right () <- targetScale identifier renderer texture | Left err => pure (Left err)
    Right () <- retainedScale identifier renderer texture | Left err => pure (Left err)
    Right () <- targetLogical identifier renderer texture | Left err => pure (Left err)
    retainedLogical identifier renderer texture
  target <- setRenderTarget renderer Nothing
  logical <- setRenderLogicalPresentation renderer 0 0 PresentationDisabled
  scale <- setRenderScale renderer 1 1
  destroyTexture texture
  if target && logical && scale then pure result else pure (Left "Cannot restore renderer scale after tests")
