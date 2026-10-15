module ResourceHelperTests

import SDL3.Internal.Resource

import Data.IORef

%default covering

%foreign "C:idris_test_error, libidris2_sdl3_test, extended_fixtures.h"
prim__error : String -> PrimIO ()

recordCall : IORef (List String) -> String -> IO ()
recordCall calls name = modifyIORef calls (++ [name])

stateCase : Bool -> Bool -> Bool -> Bool -> IO (Either String ())
stateCase queryOK setOK actionOK restoreOK = do
  calls <- newIORef (the (List String) [])
  let query : IO (Either String Int) = do
        recordCall calls "query"
        pure (if queryOK then Right 7 else Left "query failure")
  let set : Int -> IO Bool = \value => do
        let restoring = value == 7
        let name = if restoring then "restore" else "set"
        recordCall calls name
        -- Even successful cleanup can replace SDL's error. Earlier errors must already be copied.
        primIO (prim__error (name ++ " failure"))
        pure (if restoring then restoreOK else setOK)
  let action : IO (Either String Int) = do
        recordCall calls "action"
        pure (if actionOK then Right 42 else Left "action failure")
  result <- withState query set 9 action
  actual <- readIORef calls
  let expected : Either String Int =
        if not queryOK then Left "query failure" else
        if not setOK then Left "set failure" else
        if not actionOK then Left "action failure" else
        if not restoreOK then Left "restore failure" else Right 42
  let order = if not queryOK then ["query"] else
              if not setOK then ["query", "set", "restore"] else ["query", "set", "action", "restore"]
  pure (if result == expected && actual == order then Right () else Left "State helper changed call order or error precedence")

resourceCase : Bool -> Bool -> Bool -> IO (Either String ())
resourceCase acquired actionOK released = do
  calls <- newIORef (the (List String) [])
  let acquire : IO (Either String ()) = pure (if acquired then Right () else Left "acquisition failure")
  let action : () -> IO (Either String Int) = \_ => do
        recordCall calls "action"
        pure (if actionOK then Right 42 else Left "action failure")
  let release : () -> IO Bool = \_ => do
        recordCall calls "release"
        primIO (prim__error "release failure")
        pure released
  result <- withCheckedResource acquire release action
  actual <- readIORef calls
  let expected : Either String Int =
        if not acquired then Left "acquisition failure" else
        if not actionOK then Left "action failure" else
        if not released then Left "release failure" else Right 42
  pure (if result == expected && actual == (if acquired then ["action", "release"] else [])
          then Right () else Left "Resource helper changed cleanup or error precedence")

libraryCase : Bool -> Bool -> IO (Either String ())
libraryCase started actionOK = do
  calls <- newIORef (the (List String) [])
  let start = do
        recordCall calls "start"
        primIO (prim__error "start failure")
        pure started
  let stop = do
        recordCall calls "stop"
        primIO (prim__error "shutdown ran")
  let action : IO (Either String Int) = do
        recordCall calls "action"
        pure (if actionOK then Right 42 else Left "action failure")
  result <- withLibrary start stop action
  actual <- readIORef calls
  let expected : Either String Int = if not started then Left "start failure" else
        if actionOK then Right 42 else Left "action failure"
  pure (if result == expected && actual == (if started then ["start", "action", "stop"] else ["start"])
          then Right () else Left "Library helper changed initialization or cleanup")

runCases : List (IO (Either String ())) -> IO (Either String ())
runCases [] = pure (Right ())
runCases (test :: rest) = do
  Right () <- test | Left err => pure (Left err)
  runCases rest

export
resourceHelperTests : IO (Either String ())
resourceHelperTests = runCases $
  [stateCase q s a r | q <- [False, True], s <- [False, True], a <- [False, True], r <- [False, True]] ++
  [resourceCase q a r | q <- [False, True], a <- [False, True], r <- [False, True]] ++
  [libraryCase q a | q <- [False, True], a <- [False, True]]
