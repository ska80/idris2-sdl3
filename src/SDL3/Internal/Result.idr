||| SDL result conversion shared by core and extensions. Not an application API.
module SDL3.Internal.Result

import SDL3.Raw

%default total

export
nullable : (pointer -> PrimIO Int) -> (pointer -> value) -> PrimIO pointer -> IO (Either String value)
nullable isNull wrap action = do
  ptr <- primIO action
  0 <- primIO (isNull ptr) | _ => Left <$> primIO prim__getError
  pure (Right (wrap ptr))

export
owned : (AnyPtr -> value) -> PrimIO AnyPtr -> IO (Either String value)
owned = nullable prim__isNull

export
nonnegative64 : PrimIO Int64 -> IO (Either String Bits64)
nonnegative64 action = do
  value <- primIO action
  if value < 0 then Left <$> primIO prim__getError else pure (Right (cast value))
