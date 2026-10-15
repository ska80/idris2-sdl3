module Main

import SDL3
import SDL3.Scoped

import Data.Buffer
import System

%default covering

-- Preparation includes loop arithmetic and Idris value construction.
points : PointBuffer -> Bits32 -> Nat -> IO Bool
points buffer index Z = pure True
points buffer index (S n) = do
  True <- setPoint buffer index (MkPoint (cast (index `mod` 64)) (cast (index `div` 64))) | False => pure False
  points buffer (index + 1) n

packed : Buffer -> Int -> Bits32 -> Nat -> Bool -> IO ()
packed buffer offset index Z rectangles = pure ()
packed buffer offset index (S n) rectangles = do
  setDouble buffer offset (cast (index `mod` 64))
  setDouble buffer (offset + 8) (cast (index `div` 64))
  case rectangles of
    True => do
      setDouble buffer (offset + 16) 1
      setDouble buffer (offset + 24) 1
      packed buffer (offset + 32) (index + 1) n rectangles
    False => packed buffer (offset + 16) (index + 1) n rectangles

rectangles : RectBuffer -> Bits32 -> Nat -> IO Bool
rectangles buffer index Z = pure True
rectangles buffer index (S n) = do
  True <- setRect buffer index (MkFRect (cast (index `mod` 64)) (cast (index `div` 64)) 1 1) | False => pure False
  rectangles buffer (index + 1) n

quadIndices : GeometryBuffer -> Bits32 -> Nat -> IO Bool
quadIndices buffer quad Z = pure True
quadIndices buffer quad (S n) = do
  let v = quad * 4
  let i = quad * 6
  True <- setGeometryIndex buffer i v | False => pure False
  True <- setGeometryIndex buffer (i+1) (v+1) | False => pure False
  True <- setGeometryIndex buffer (i+2) (v+2) | False => pure False
  True <- setGeometryIndex buffer (i+3) v | False => pure False
  True <- setGeometryIndex buffer (i+4) (v+2) | False => pure False
  True <- setGeometryIndex buffer (i+5) (v+3) | False => pure False
  quadIndices buffer (quad + 1) n

quadVertices : GeometryBuffer -> Bits32 -> Nat -> IO Bool
quadVertices buffer quad Z = pure True
quadVertices buffer quad (S n) = do
  let x : Double = cast ((quad `mod` 32) * 2)
  let y : Double = cast ((quad `div` 32) * 2)
  let v = quad * 4
  let color = MkColor 220 100 30 255
  True <- setVertex buffer v (MkVertex (MkPoint x y) color 0 0) | False => pure False
  True <- setVertex buffer (v+1) (MkVertex (MkPoint (x+1) y) color 1 0) | False => pure False
  True <- setVertex buffer (v+2) (MkVertex (MkPoint (x+1) (y+1)) color 1 1) | False => pure False
  True <- setVertex buffer (v+3) (MkVertex (MkPoint x (y+1)) color 0 1) | False => pure False
  quadVertices buffer (quad + 1) n

sample : Renderer -> IO Bool -> IO Bool -> IO (Either String (Bits64, Bits64))
sample renderer prepare submit = do
  True <- clear renderer | False => Left <$> getError
  a <- performanceCounter
  True <- prepare | False => Left <$> getError
  b <- performanceCounter
  True <- submit | False => Left <$> getError
  c <- performanceCounter
  -- Present can execute queued rendering. Its time is deliberately excluded.
  True <- present renderer | False => Left <$> getError
  pure (Right (b-a, c-b))

samples : Nat -> Renderer -> IO Bool -> IO Bool -> Bits64 -> Bits64 -> IO (Either String (Bits64, Bits64))
samples Z renderer prepare submit p s = pure (Right (p, s))
samples (S n) renderer prepare submit p s = do
  Right (dp, ds) <- sample renderer prepare submit | Left err => pure (Left err)
  samples n renderer prepare submit (p+dp) (s+ds)

measure : String -> Renderer -> IO Bool -> IO Bool -> IO (Either String ())
measure name renderer prepare submit = do
  Right _ <- samples 20 renderer prepare submit 0 0 | Left err => pure (Left err)
  Right (p, s) <- samples 200 renderer prepare submit 0 0 | Left err => pure (Left err)
  frequency <- performanceFrequency
  let divisor : Double = cast frequency * 200 / 1000000
  putStrLn (name ++ ": prepare_us=" ++ show (cast p / divisor) ++ ", submit_us=" ++ show (cast s / divisor))
  pure (Right ())

run : IO (Either String ())
run = withWindow "Batch CPU timing" 128 128 hidden $ \window => withRenderer window $ \renderer =>
  withPointBuffer 4096 $ \pointBuffer => withRectBuffer 4096 $ \rectBuffer =>
    withGeometryBuffer 4096 6144 $ \geometry => do
      Just source <- newBuffer (4096 * 32) | Nothing => pure (Left "Cannot allocate packed batch source")
      True <- setDrawColor renderer 220 100 30 255 | False => Left <$> getError
      Right () <- measure "4096 scalar point updates" renderer (points pointBuffer 0 4096) (drawPoints renderer pointBuffer 4096)
        | Left err => pure (Left err)
      Right () <- measure "4096 packed points plus copy" renderer (do
        packed source 0 0 4096 False
        copyPoints pointBuffer 0 source 0 4096) (drawPoints renderer pointBuffer 4096) | Left err => pure (Left err)
      Right () <- measure "4096 point copy only" renderer (copyPoints pointBuffer 0 source 0 4096) (drawPoints renderer pointBuffer 4096)
        | Left err => pure (Left err)
      Right () <- measure "4096 scalar rectangle updates" renderer (rectangles rectBuffer 0 4096) (fillRects renderer rectBuffer 4096)
        | Left err => pure (Left err)
      Right () <- measure "4096 packed rectangles plus copy" renderer (do
        packed source 0 0 4096 True
        copyRects rectBuffer 0 source 0 4096) (fillRects renderer rectBuffer 4096) | Left err => pure (Left err)
      Right () <- measure "4096 rectangle copy only" renderer (copyRects rectBuffer 0 source 0 4096) (fillRects renderer rectBuffer 4096)
        | Left err => pure (Left err)
      True <- quadIndices geometry 0 1024 | False => Left <$> getError
      measure "1024 indexed quads, reused indices" renderer (quadVertices geometry 0 1024) (drawGeometry renderer geometry 4096 6144)

main : IO ()
main = do
  True <- init video | False => do
    err <- getError
    quit
    putStrLn err
    exitFailure
  result <- run
  quit
  case result of
    Right () => pure ()
    Left err => do
      putStrLn err
      exitFailure
