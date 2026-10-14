module ImageMain

import SDL3
import SDL3.Scoped
import SDL3.Image
import SDL3.Image.Scoped

import Data.Buffer
import Data.IORef

import System
import System.File

%default covering

%foreign "C:idris_test_make_image, libidris2_sdl3_image_test, image_fixtures.h"
prim__fixture : Int32 -> PrimIO String

failing "Mismatch between"
  imageAsTarget : Renderer -> Texture StaticAccess -> IO Bool
  imageAsTarget renderer texture = setRenderTarget renderer (Just texture)

failing "Mismatch between"
  wrongStream : Renderer -> Window -> IO (Either String (Texture StaticAccess))
  wrongStream renderer window = loadTextureIO renderer window

failing "Name SDL3.MkSurface is private"
  forgeSurface : AnyPtr -> Surface
  forgeSurface = MkSurface

failing "Undefined name unsafeHandlePointer"
  leakRenderer : Renderer -> AnyPtr
  leakRenderer = unsafeHandlePointer

checkTexture : Renderer -> Texture StaticAccess -> IO (Either String ())
checkTexture renderer texture = do
  Right (MkSize 3 2) <- getTextureSize texture | _ => pure (Left "Wrong image dimensions")
  True <- renderTexture renderer texture Nothing | False => Left <$> getError
  pure (Right ())

fileTests : Renderer -> String -> IO (Either String ())
fileTests renderer path = do
  Right () <- withSurface path (\surface => withTextureFromSurface renderer surface (checkTexture renderer))
    | Left err => pure (Left err)
  Right () <- withTexture renderer path (checkTexture renderer) | Left err => pure (Left err)
  -- The texture survives stream cleanup, without transferring stream ownership to the decoder.
  Right texture <- withFileIO path ReadFile (\stream => do
    Right () <- withSurfaceIO stream (\surface => withTextureFromSurface renderer surface (checkTexture renderer))
      | Left err => pure (Left err)
    Right 0 <- seekIO stream 0 FromStart | _ => pure (Left "Decoder closed the borrowed stream")
    loadTextureIO renderer stream) | Left err => pure (Left err)
  result <- checkTexture renderer texture
  destroyTexture texture
  pure result

memoryTests : Renderer -> String -> IO (Either String ())
memoryTests renderer path = withFileIO path ReadFile $ \file => do
  Right size <- getIOSize file | Left err => pure (Left err)
  Just bytes <- newBuffer (cast size) | Nothing => pure (Left "Cannot allocate image input")
  Right copied <- readIO file bytes 0 size | Left err => pure (Left err)
  True <- pure (copied.transferred == size) | False => pure (Left "Incomplete fixture read")
  withMemoryIO bytes $ \stream => withTextureIO renderer stream (checkTexture renderer)

failureTests : Renderer -> IO (Either String ())
failureTests renderer = do
  called <- newIORef False
  Left _ <- withTexture renderer "/nonexistent/idris-image" (\texture => do
    writeIORef called True
    pure (Right ())) | Right () => pure (Left "Missing image loaded")
  False <- readIORef called | True => pure (Left "Failed image load ran callback")
  withMemoryIO !(newBadBuffer) $ \stream => do
    Left _ <- loadSurfaceIO stream | Right surface => do
      destroySurface surface
      pure (Left "Invalid image decoded")
    Right 0 <- seekIO stream 0 FromStart | _ => pure (Left "Failed decoding closed stream")
    Left _ <- loadTextureIO renderer stream | Right texture => do
      destroyTexture texture
      pure (Left "Invalid image became a texture")
    Right 4 <- getIOSize stream | _ => pure (Left "Failed texture loading closed stream")
    pure (Right ())
  where
    newBadBuffer : IO Buffer
    newBadBuffer = do
      Just buffer <- newBuffer 4 | Nothing => die "Cannot allocate test input"
      setBits32 buffer 0 0
      pure buffer

runFormat : Renderer -> Int32 -> IO (Either String ())
runFormat renderer jpeg = do
  path <- primIO (prim__fixture jpeg)
  case path == "" of
    True => Left <$> getError
    False => do
      result <- fileTests renderer path
      memory <- memoryTests renderer path
      callback <- withSurface path (\surface => pure (the (Either String ()) (Left "image callback")))
      _ <- removeFile path
      Right () <- pure result | Left err => pure (Left err)
      Right () <- pure memory | Left err => pure (Left err)
      Left "image callback" <- pure callback | _ => pure (Left "Image scope changed callback error")
      pure (Right ())

main : IO ()
main = do
  True <- SDL3.init video | False => do
    getError >>= putStrLn
    SDL3.quit
    exitFailure
  result <- withWindow "image tests" 8 8 hidden $ \window => withRenderer window $ \renderer => do
    Right () <- runFormat renderer 0 | Left err => pure (Left err)
    Right () <- runFormat renderer 1 | Left err => pure (Left err)
    failureTests renderer
  SDL3.quit
  case result of
    Right () => putStrLn "Image Idris tests passed"
    Left err => do putStrLn err; exitFailure
