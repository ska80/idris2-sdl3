module BlendCompositionTests

import SDL3
import SDL3.Scoped
import Data.IORef

%default covering

%foreign "C:idris_test_compose_blend, libidris2_sdl3_test, fixtures.h"
prim__reference : Int -> Int -> PrimIO Bits32

reference : Int -> Int -> BlendEquation -> BlendEquation -> IO (Either String ())
reference slot choice rgb alpha = do
  expected <- primIO (prim__reference slot choice)
  actual <- composeBlendMode rgb alpha
  if actual == OtherBlendMode expected then pure (Right ())
     else pure (Left "Blend composition differed from the SDL header reference")

factorCases : Int -> List BlendFactor -> IO (Either String ())
factorCases index [] = pure (Right ())
factorCases index (factor :: rest) = do
  Right () <- reference 0 index (MkBlendEquation factor ZeroFactor BlendAdd)
    (MkBlendEquation SourceAlphaFactor DestinationAlphaFactor BlendMaximum) | Left err => pure (Left err)
  Right () <- reference 1 index (MkBlendEquation OneFactor factor BlendAdd)
    (MkBlendEquation SourceAlphaFactor DestinationAlphaFactor BlendMaximum) | Left err => pure (Left err)
  Right () <- reference 3 index (MkBlendEquation OneFactor ZeroFactor BlendAdd)
    (MkBlendEquation factor DestinationAlphaFactor BlendMaximum) | Left err => pure (Left err)
  Right () <- reference 4 index (MkBlendEquation OneFactor ZeroFactor BlendAdd)
    (MkBlendEquation SourceAlphaFactor factor BlendMaximum) | Left err => pure (Left err)
  factorCases (index + 1) rest

operationCases : Int -> List BlendOperation -> IO (Either String ())
operationCases index [] = pure (Right ())
operationCases index (operation :: rest) = do
  Right () <- reference 2 index (MkBlendEquation OneFactor ZeroFactor operation)
    (MkBlendEquation SourceAlphaFactor DestinationAlphaFactor BlendMaximum) | Left err => pure (Left err)
  Right () <- reference 5 index (MkBlendEquation OneFactor ZeroFactor BlendAdd)
    (MkBlendEquation SourceAlphaFactor DestinationAlphaFactor operation) | Left err => pure (Left err)
  operationCases (index + 1) rest

named : BlendEquation -> BlendEquation -> BlendMode -> IO (Either String ())
named rgb alpha expected = do
  actual <- composeBlendMode rgb alpha
  case actual of
    OtherBlendMode _ => pure (Left "A predefined composition did not return a named blend mode")
    _ => if actual == expected then pure (Right ()) else pure (Left "Predefined blend composition returned an incorrect mode")

namedCases : IO (Either String ())
namedCases = do
  let replace = MkBlendEquation OneFactor ZeroFactor BlendAdd
  let keepAlpha = MkBlendEquation ZeroFactor OneFactor BlendAdd
  let overAlpha = MkBlendEquation OneFactor OneMinusSourceAlphaFactor BlendAdd
  Right () <- named replace replace NoBlend | Left err => pure (Left err)
  Right () <- named (MkBlendEquation SourceAlphaFactor OneMinusSourceAlphaFactor BlendAdd)
    overAlpha AlphaBlend | Left err => pure (Left err)
  Right () <- named overAlpha overAlpha PremultipliedAlphaBlend | Left err => pure (Left err)
  Right () <- named (MkBlendEquation SourceAlphaFactor OneFactor BlendAdd)
    keepAlpha AdditiveBlend | Left err => pure (Left err)
  Right () <- named (MkBlendEquation OneFactor OneFactor BlendAdd)
    keepAlpha PremultipliedAdditiveBlend | Left err => pure (Left err)
  Right () <- named (MkBlendEquation ZeroFactor SourceColorFactor BlendAdd)
    keepAlpha ModulateBlend | Left err => pure (Left err)
  named (MkBlendEquation DestinationColorFactor OneMinusSourceAlphaFactor BlendAdd)
    keepAlpha MultiplyBlend

checkAction : IORef Bool -> Either String () -> IO (Either String ())
checkAction called result = do
  ran <- readIORef called
  case result of
    Right () => if ran then pure (Right ()) else pure (Left "Supported composition skipped its action")
    Left err => if ran || err == "" then pure (Left "Composition failed after running its action or lost its error")
                  else pure (Right ())

supportTests : Renderer -> BlendMode -> IO (Either String ())
supportTests renderer mode = withTargetTexture renderer 8 8 $ \texture =>
  withDrawBlendMode renderer AlphaBlend $ do
    True <- setTextureBlendMode texture AlphaBlend | False => Left <$> getError
    textureCalled <- newIORef False
    textureResult <- withTextureBlendMode texture mode $ do
      writeIORef textureCalled True
      Right actual <- getTextureBlendMode texture | Left err => pure (Left err)
      if actual == mode then pure (Right ()) else pure (Left "Accepted custom texture mode was not preserved")
    Right () <- checkAction textureCalled textureResult | Left err => pure (Left err)
    Right AlphaBlend <- getTextureBlendMode texture | _ => pure (Left "Custom texture mode was not restored")
    drawCalled <- newIORef False
    drawResult <- withDrawBlendMode renderer mode $ do
      writeIORef drawCalled True
      Right actual <- getDrawBlendMode renderer | Left err => pure (Left err)
      if actual == mode then pure (Right ()) else pure (Left "Accepted custom draw mode was not preserved")
    Right () <- checkAction drawCalled drawResult | Left err => pure (Left err)
    Right AlphaBlend <- getDrawBlendMode renderer | _ => pure (Left "Custom draw mode was not restored")
    pure (Right ())

export
blendCompositionTests : Renderer -> IO (Either String ())
blendCompositionTests renderer = do
  Right () <- factorCases 0 [ZeroFactor, OneFactor, SourceColorFactor, OneMinusSourceColorFactor,
    SourceAlphaFactor, OneMinusSourceAlphaFactor, DestinationColorFactor, OneMinusDestinationColorFactor,
    DestinationAlphaFactor, OneMinusDestinationAlphaFactor] | Left err => pure (Left err)
  Right () <- operationCases 0 [BlendAdd, BlendSubtract, BlendReverseSubtract, BlendMinimum, BlendMaximum]
    | Left err => pure (Left err)
  Right () <- namedCases | Left err => pure (Left err)
  let rgb = MkBlendEquation OneFactor OneFactor BlendReverseSubtract
  let alpha = MkBlendEquation ZeroFactor OneFactor BlendAdd
  mode <- composeBlendMode rgb alpha
  OtherBlendMode _ <- pure mode | _ => pure (Left "A custom equation became an unrelated predefined mode")
  repeated <- composeBlendMode rgb alpha
  if mode /= repeated then pure (Left "Repeated blend composition changed its code")
     else supportTests renderer mode
