module IOTests

import SDL3
import SDL3.Scoped
import Data.Buffer
import Data.IORef
import System.File

%default covering

%foreign "C:idris_test_make_wav, libidris2_sdl3_test, audio_fixtures.h"
prim__makeFile : PrimIO String

memory : Buffer -> IOStream -> IO (Either String ())
memory source stream = do
  setBits8 source 0 99
  Right 4 <- getIOSize stream | _ => pure (Left "Copied memory size was incorrect")
  Right 0 <- tellIO stream | _ => pure (Left "Copied memory was not rewound")
  Just target <- newBuffer 8 | Nothing => pure (Left "Cannot allocate IO test buffer")
  setBits8 target 0 77
  setBits8 target 5 88
  Right (MkIOTransfer 4 IOReady Nothing) <- readIO stream target 1 4 | _ => pure (Left "Memory read failed")
  1 <- getBits8 target 1 | _ => pure (Left "Memory stream retained its source buffer")
  4 <- getBits8 target 4 | _ => pure (Left "Memory read lost its last byte")
  77 <- getBits8 target 0 | _ => pure (Left "Memory read damaged prefix")
  88 <- getBits8 target 5 | _ => pure (Left "Memory read damaged suffix")
  Right (MkIOTransfer 0 IOEndOfFile Nothing) <- readIO stream target 0 1 | _ => pure (Left "EOF was not preserved")
  Right (MkIOTransfer 0 IOEndOfFile Nothing) <- readIO stream target 8 0 | _ => pure (Left "Zero read changed EOF status")
  Left _ <- readIO stream target 7 2 | Right _ => pure (Left "Out-of-bounds read was accepted")
  Left _ <- writeIO stream target 0xffffffffffffffff 1 | Right _ => pure (Left "Overflowing write offset was accepted")
  Left _ <- readIO stream target 0 0xffffffffffffffff | Right _ => pure (Left "Overflowing read length was accepted")
  Right 0 <- seekIO stream (-4) FromEnd | _ => pure (Left "Signed seek offset was incorrect")
  Right (MkIOTransfer 4 IOEndOfFile Nothing) <- readIO stream target 0 8 | _ => pure (Left "Partial read lost count or EOF")
  Right 4 <- tellIO stream | _ => pure (Left "Read position was incorrect")
  Right (MkIOTransfer 4 IOReady Nothing) <- writeIO stream source 0 4 | _ => pure (Left "Memory stream did not grow")
  Right 8 <- getIOSize stream | _ => pure (Left "Expanded memory size was incorrect")
  True <- flushIO stream | False => Left <$> getError
  pure (Right ())

fileRead : IOStream -> IO (Either String ())
fileRead stream = do
  Just buffer <- newBuffer 4 | Nothing => pure (Left "Cannot allocate file test buffer")
  Right (MkIOTransfer 4 IOReady Nothing) <- readIO stream buffer 0 4 | _ => pure (Left "File read failed")
  82 <- getBits8 buffer 0 | _ => pure (Left "WAV header did not start with R")
  Right transfer <- writeIO stream buffer 0 4 | Left err => pure (Left err)
  Right (MkIOTransfer 0 _ Nothing) <- writeIO stream buffer 0 0
    | _ => pure (Left "Zero transfer reported an old error as a new failure")
  if transfer.transferred /= 0 then pure (Left "Read-only file accepted a write") else
    case transfer.error of
      Nothing => pure (Left "Read-only write failure lost its error")
      Just "" => pure (Left "Read-only write error was empty")
      Just _ => pure (Right ())

fileTests : String -> IO (Either String ())
fileTests path = do
  Right () <- withFileIO path ReadFile fileRead | Left err => pure (Left err)
  Right () <- withFileIO path RewriteFile (\stream => do
    Right 0 <- getIOSize stream | _ => pure (Left "RewriteFile did not truncate")
    Just buffer <- newBuffer 1 | Nothing => pure (Left "Cannot allocate write test buffer")
    setBits8 buffer 0 42
    Right (MkIOTransfer 1 IOReady Nothing) <- writeIO stream buffer 0 1 | _ => pure (Left "File write failed")
    pure (Right ())) | Left err => pure (Left err)
  Right () <- withFileIO path AppendFile (\stream => do
    Just buffer <- newBuffer 1 | Nothing => pure (Left "Cannot allocate append test buffer")
    setBits8 buffer 0 43
    Right (MkIOTransfer 1 IOReady Nothing) <- writeIO stream buffer 0 1 | _ => pure (Left "File append failed")
    pure (Right ())) | Left err => pure (Left err)
  withFileIO path ReadFile $ \stream => do
    Right 2 <- getIOSize stream | _ => pure (Left "Append did not preserve file data")
    Just buffer <- newBuffer 2 | Nothing => pure (Left "Cannot allocate file check buffer")
    Right (MkIOTransfer 2 IOReady Nothing) <- readIO stream buffer 0 2 | _ => pure (Left "File check read failed")
    42 <- getBits8 buffer 0 | _ => pure (Left "Original file data changed")
    43 <- getBits8 buffer 1 | _ => pure (Left "Appended file data changed")
    pure (Right ())

export
ioTests : IO (Either String ())
ioTests = do
  Just source <- newBuffer 4 | Nothing => pure (Left "Cannot allocate source buffer")
  setBits8 source 0 1
  setBits8 source 1 2
  setBits8 source 2 3
  setBits8 source 3 4
  Right () <- withMemoryIO source (memory source) | Left err => pure (Left err)
  result <- withMemoryIO source $ \stream => pure (the (Either String Bits64) (Left "IO callback error"))
  Left "IO callback error" <- pure result | _ => pure (Left "IO scope changed callback error")
  result <- withMemoryIO source $ \stream => pure (Right (the Bits64 0x100000002))
  Right 0x100000002 <- pure result | _ => pure (Left "IO scope changed callback result")
  path <- primIO prim__makeFile
  if path == "" then pure (Left "Cannot create IO fixture") else do
    result <- fileTests path
    _ <- removeFile path
    called <- newIORef False
    Left _ <- withFileIO path ReadFile (\stream => do
      writeIORef called True
      pure (Right ())) | Right () => pure (Left "Missing file was accepted")
    False <- readIORef called | True => pure (Left "Failed file acquisition ran callback")
    pure result
