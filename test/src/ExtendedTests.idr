module ExtendedTests

import SDL3
import SDL3.Scoped
import SDL3.Raw

import Data.Buffer
import Data.IORef

%default covering

failing "Mismatch between"
  wrongGeometry : Renderer -> PointBuffer -> IO Bool
  wrongGeometry renderer buffer = drawGeometry renderer buffer 3 0

failing "Name SDL3.MkGeometryBuffer is private"
  forgeGeometry : AnyPtr -> GeometryBuffer
  forgeGeometry = MkGeometryBuffer

failing "Mismatch between"
  wrongSnapshot : MouseStateBuffer -> Scancode -> IO Bool
  wrongSnapshot = keyDown

failing "Mismatch between"
  wrongOutputUnits : Renderer -> RenderStateBuffer -> IO (Either String (Size PixelUnits))
  wrongOutputUnits = getCurrentRenderOutputSize

failing "Mismatch between"
  wrongLabel : Gamepad -> GamepadAxis -> IO GamepadButtonLabel
  wrongLabel = getGamepadButtonLabel

failing "Name SDL3.MkKeyboardSnapshot is private"
  forgeKeyboard : AnyPtr -> KeyboardSnapshot
  forgeKeyboard = MkKeyboardSnapshot

failing "Name SDL3.MkMouseStateBuffer is private"
  forgeMouse : NativeMouseState -> MouseStateBuffer
  forgeMouse = MkMouseStateBuffer

failing "Name SDL3.MkRenderStateBuffer is private"
  forgeRenderState : NativeRenderState -> RenderStateBuffer
  forgeRenderState = MkRenderStateBuffer

failing "Mismatch between"
  wrongKey : KeyboardSnapshot -> Keycode -> IO Bool
  wrongKey = keyDown

failing "Mismatch between"
  wrongVertexSpace : Point WindowSpace -> Vertex
  wrongVertexSpace point = MkVertex point (MkColor 255 255 255 255) 0 0

%foreign "C:idris_test_render_reset, libidris2_sdl3_test, extended_fixtures.h"
prim__reset : Int32 -> PrimIO Int

vertices : GeometryBuffer -> Bits32 -> List Vertex -> IO Bool
vertices buffer index [] = pure True
vertices buffer index (value :: rest) = do
  True <- setVertex buffer index value | False => pure False
  vertices buffer (index + 1) rest

indices : GeometryBuffer -> Bits32 -> List Bits32 -> IO Bool
indices buffer index [] = pure True
indices buffer index (value :: rest) = do
  True <- setGeometryIndex buffer index value | False => pure False
  indices buffer (index + 1) rest

geometryTests : Renderer -> IO (Either String ())
geometryTests renderer = withGeometryBuffer 4 6 $ \buffer => do
  let red = MkColor 255 0 0 255
  True <- vertices buffer 0 [MkVertex (MkPoint 0 0) red 0 0, MkVertex (MkPoint 8 0) red 1 0,
                              MkVertex (MkPoint 8 8) red 1 1, MkVertex (MkPoint 0 8) red 0 1]
    | False => Left <$> getError
  True <- indices buffer 0 [0,1,2,0,2,3] | False => Left <$> getError
  True <- drawGeometry renderer buffer 4 6 | False => Left <$> getError
  False <- drawGeometry renderer buffer 3 6 | True => pure (Left "Geometry accepted an invalid vertex prefix")
  False <- drawGeometry renderer buffer 4 5 | True => pure (Left "Geometry accepted an incomplete triangle")
  False <- setGeometryIndex buffer 0 4 | True => pure (Left "Geometry accepted an invalid vertex reference")
  withTargetTexture renderer 8 8 $ \texture => do
    Right () <- withRenderTarget renderer (Just texture) (do
      True <- setDrawColor renderer 255 255 255 255 | False => Left <$> getError
      True <- clear renderer | False => Left <$> getError
      pure (Right ())) | Left err => pure (Left err)
    True <- renderGeometry renderer texture buffer 4 6 | False => Left <$> getError
    pure (Right ())

bulkTests : Renderer -> IO (Either String ())
bulkTests renderer = withPointBuffer 2 $ \points => withRectBuffer 1 $ \rects => do
  Just bytes <- newBuffer 32 | Nothing => pure (Left "Cannot allocate packed batch input")
  setDouble bytes 0 1
  setDouble bytes 8 2
  setDouble bytes 16 3
  setDouble bytes 24 4
  True <- copyPoints points 0 bytes 0 2 | False => Left <$> getError
  True <- drawPoints renderer points 2 | False => Left <$> getError
  False <- copyPoints points 1 bytes 0 2 | True => pure (Left "Point destination overflow accepted")
  False <- copyPoints points 0 bytes 1 2 | True => pure (Left "Point source overflow accepted")
  True <- copyRects rects 0 bytes 0 1 | False => Left <$> getError
  True <- fillRects renderer rects 1 | False => Left <$> getError
  False <- copyRects rects 0 bytes 0xffffffffffffffff 1 | True => pure (Left "Rectangle offset overflow accepted")
  pure (Right ())

stateTests : Renderer -> RenderStateBuffer -> IO (Either String ())
stateTests renderer buffer = do
  Right Nothing <- getRenderViewport renderer buffer | _ => pure (Left "Default viewport was explicit")
  Right () <- withRenderViewport renderer buffer (Just (MkRect 1 2 8 9)) (do
    Right (Just (MkRect 1 2 8 9)) <- getRenderViewport renderer buffer | _ => pure (Left "Viewport query was wrong")
    withRenderClipRect renderer buffer (Just (MkRect 0 0 0 0)) $ do
      Right (Just (MkRect 0 0 0 0)) <- getRenderClipRect renderer buffer | _ => pure (Left "Empty clip was disabled")
      pure (Right ())) | Left err => pure (Left err)
  Right Nothing <- getRenderViewport renderer buffer | _ => pure (Left "Scope lost automatic viewport")
  Right Nothing <- getRenderClipRect renderer buffer | _ => pure (Left "Clip scope did not restore disabled state")
  result <- withRenderScale renderer buffer 1.5 2.5 $ do
    Right (1.5, 2.5) <- getRenderScale renderer buffer | _ => pure (Left "Scale query was wrong")
    pure (the (Either String ()) (Left "scale action"))
  Left "scale action" <- pure result | _ => pure (Left "Scale scope changed callback error")
  Right (1.0, 1.0) <- getRenderScale renderer buffer | _ => pure (Left "Scale scope failed to restore")
  True <- setDrawColor renderer 17 34 51 68 | False => Left <$> getError
  let query = getDrawColor renderer buffer
  Right (MkColor 17 34 51 68) <- query | _ => pure (Left "Draw color query was wrong")
  Right () <- withDrawColor renderer buffer (MkColor 255 0 128 255) (do
    Right (MkColor 255 0 128 255) <- query | _ => pure (Left "Cached draw color query was stale")
    pure (Right ())) | Left err => pure (Left err)
  Right (MkColor 17 34 51 68) <- query | _ => pure (Left "Draw color scope did not restore")
  called <- newIORef False
  Left _ <- withRenderViewport renderer buffer (Just (MkRect 0 0 (-1) 1)) (do
    writeIORef called True
    pure (Right ())) | Right () => pure (Left "Invalid viewport was accepted")
  False <- readIORef called | True => pure (Left "Failed state setting ran action")
  Right Nothing <- getRenderViewport renderer buffer | _ => pure (Left "Failed state setting lost old viewport")
  pure (Right ())

outputTests : Renderer -> RenderStateBuffer -> IO (Either String ())
outputTests renderer buffer = do
  Right (MkSize 16 16) <- getRenderOutputSize renderer buffer | _ => pure (Left "Window output dimensions were wrong")
  withTargetTexture renderer 8 8 $ \texture => do
    Right () <- withTextureColorMod texture (MkRGB 17 34 51) (do
      Right (MkRGB 17 34 51) <- getTextureColorMod texture | _ => pure (Left "Texture color query was wrong")
      pure (Right ())) | Left err => pure (Left err)
    Right (MkRGB 255 255 255) <- getTextureColorMod texture | _ => pure (Left "Texture color scope did not restore")
    withRenderTarget renderer (Just texture) $ do
      Right (MkSize 8 8) <- getCurrentRenderOutputSize renderer buffer | _ => pure (Left "Current output ignored texture size")
      True <- setRenderLogicalPresentation renderer 4 4 PresentationStretch | False => Left <$> getError
      Right _ <- getRenderOutputSize renderer buffer | Left err => pure (Left err)
      Right _ <- getCurrentRenderOutputSize renderer buffer | Left err => pure (Left err)
      pure (Right ())

inputTests : IO (Either String ())
inputTests = withKeyboardSnapshot $ \keyboard => withMouseStateBuffer $ \mouse => do
  pumpEvents
  True <- refreshKeyboardSnapshot keyboard | False => Left <$> getError
  False <- keyDown keyboard (MkScancode 0xffffffff) | True => pure (Left "Unknown scancode reported pressed")
  Right copied <- getMouseState mouse | Left err => pure (Left err)
  Right _ <- getRelativeMouseState mouse | Left err => pure (Left err)
  Right (MkRelativeMouseState _ 0.0 0.0) <- getRelativeMouseState mouse | _ => pure (Left "Relative query did not reset motion")
  pure (Right ())

resetTests : IO (Either String ())
resetTests = withEventBuffer $ \buffer => do
  1 <- primIO (prim__reset 0) | _ => Left <$> getError
  Right (Just (RenderTargetsResetEvent 0x100000002 (MkWindowID 0xffffffff))) <- waitEventDataTimeout buffer 20
    | _ => pure (Left "Render target reset event was wrong")
  1 <- primIO (prim__reset 1) | _ => Left <$> getError
  Right (RenderDeviceResetEvent 0x100000002 (MkWindowID 0xffffffff)) <- waitEventData buffer
    | _ => pure (Left "Render device reset event was wrong")
  1 <- primIO (prim__reset 0) | _ => Left <$> getError
  first <- pollEvent buffer
  event <- the (IO (Maybe EventType)) $ case first of
    Nothing => pollEvent buffer
    Just value => pure (Just value)
  Just RenderTargetsReset <- pure event | _ => pure (Left "Render reset type was wrong")
  pure (Right ())

export
extendedTests : IO (Either String ())
extendedTests = withWindow "extended" 16 16 hidden $ \window => withRenderer window $ \renderer =>
  withRenderStateBuffer $ \buffer => do
    Right () <- geometryTests renderer | Left err => pure (Left err)
    Right () <- bulkTests renderer | Left err => pure (Left err)
    Right () <- stateTests renderer buffer | Left err => pure (Left err)
    Right () <- outputTests renderer buffer | Left err => pure (Left err)
    Right () <- inputTests | Left err => pure (Left err)
    resetTests
