||| Reusable SDL3_ttf text for the core renderer. Use this subset on the main thread.
module SDL3.TTF

import SDL3
import SDL3.Raw
import SDL3.TTF.Raw
import SDL3.Internal.Handles
import SDL3.Internal.Result

import System.FFI

%default total

||| Owned font. Destroy its text objects before closing it, and close before quitTTF.
export
data Font = MkFont AnyPtr

||| Owned renderer text engine. Its renderer must remain alive. SDL_ttf manages glyph storage.
export
data RendererTextEngine = MkRendererTextEngine AnyPtr

||| Owned text and reusable size storage. Its font, engine, and renderer must remain alive.
export
data Text = MkText AnyPtr NativeSize

export
initTTF : IO Bool
initTTF = (/= 0) <$> primIO prim__initTTF

||| Balance each successful initTTF. Close fonts first. This does not close remaining fonts.
export
quitTTF : IO ()
quitTTF = primIO prim__quitTTF

||| Point size narrows to SDL float. Rejects nonpositive, nonfinite, and out-of-range sizes.
||| File paths use UTF-8 and end at embedded NUL. Keep all operations in this subset on the main thread.
export
openFont : String -> Double -> IO (Either String Font)
openFont path size = owned MkFont (prim__openFont path size)

export
closeFont : Font -> IO ()
closeFont (MkFont ptr) = primIO (prim__closeFont ptr)

export
createRendererTextEngine : Renderer -> IO (Either String RendererTextEngine)
createRendererTextEngine renderer = owned MkRendererTextEngine $
  prim__createTextEngine (unsafeHandlePointer renderer)

||| Destroy all text objects first. The renderer remains owned by the caller.
export
destroyRendererTextEngine : RendererTextEngine -> IO ()
destroyRendererTextEngine (MkRendererTextEngine ptr) = primIO (prim__destroyTextEngine ptr)

||| Create once and reuse. SDL_ttf copies UTF-8 text, ending at embedded NUL.
||| SDL_ttf can allocate or rebuild its internal text representation when text changes.
export
createText : RendererTextEngine -> Font -> String -> IO (Either String Text)
createText (MkRendererTextEngine engine) (MkFont font) value = do
  storage <- primIO prim__newTextSize
  0 <- primIO (prim__sizeIsNull storage) | _ => Left <$> getError
  ptr <- primIO (prim__createText engine font value)
  0 <- primIO (prim__isNull ptr) | _ => do
    err <- getError
    primIO (prim__freeSize storage)
    pure (Left err)
  pure (Right (MkText ptr storage))

export
destroyText : Text -> IO ()
destroyText (MkText ptr storage) = do
  primIO (prim__destroyText ptr)
  primIO (prim__freeSize storage)

||| Replace copied UTF-8 content. Call only when the content changes, not on each draw.
export
setTextString : Text -> String -> IO Bool
setTextString (MkText ptr _) value = (/= 0) <$> primIO (prim__setTextString ptr value)

||| Width in text pixels. Zero wraps only at newline characters. Maximum 2147483647.
export
setTextWrapWidth : Text -> Bits32 -> IO Bool
setTextWrapWidth (MkText ptr _) width = (/= 0) <$> primIO (prim__setTextWrapWidth ptr width)

export
setTextColor : Text -> Bits8 -> Bits8 -> Bits8 -> Bits8 -> IO Bool
setTextColor (MkText ptr _) r g b a = (/= 0) <$> primIO (prim__setTextColor ptr r g b a)

||| Draw through the creating engine and renderer, using current renderer state.
||| Coordinates narrow to finite SDL floats. This does not clear or present the renderer.
export
drawText : Text -> Point RenderSpace -> IO Bool
drawText (MkText ptr _) (MkPoint x y) = (/= 0) <$> primIO (prim__drawText ptr x y)

||| Copy text dimensions before renderer scaling. Reuses storage owned by this text object.
||| The returned dimensions survive text cleanup and do not track later content changes.
export
getTextSize : Text -> IO (Either String (Size PixelUnits))
getTextSize (MkText ptr storage) = do
  1 <- primIO (prim__textSize ptr storage) | _ => Left <$> getError
  pure (Right (MkSize (getField storage "width") (getField storage "height")))
