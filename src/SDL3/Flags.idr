module SDL3.Flags

import Data.Bits

%default total

||| Initialization flags cannot be used as window flags.
export
data InitFlags = MkInitFlags Bits32

export
data WindowFlags = MkWindowFlags Bits64

export
initBits : InitFlags -> Bits32
initBits (MkInitFlags bits) = bits

export
windowBits : WindowFlags -> Bits64
windowBits (MkWindowFlags bits) = bits

export
Semigroup InitFlags where
  MkInitFlags x <+> MkInitFlags y = MkInitFlags (x .|. y)

export
Monoid InitFlags where
  neutral = MkInitFlags 0

export
Semigroup WindowFlags where
  MkWindowFlags x <+> MkWindowFlags y = MkWindowFlags (x .|. y)

export
Monoid WindowFlags where
  neutral = MkWindowFlags 0

export
video : InitFlags
video = MkInitFlags 0x20

export
audio : InitFlags
audio = MkInitFlags 0x10

export
events : InitFlags
events = MkInitFlags 0x4000

export
gamepad : InitFlags
gamepad = MkInitFlags 0x2000

export
fullscreen : WindowFlags
fullscreen = MkWindowFlags 1

export
hidden : WindowFlags
hidden = MkWindowFlags 8

export
borderless : WindowFlags
borderless = MkWindowFlags 0x10

export
resizable : WindowFlags
resizable = MkWindowFlags 0x20

||| Request always-on-top placement. Actual stacking depends on the window system.
export
alwaysOnTop : WindowFlags
alwaysOnTop = MkWindowFlags 0x10000

export
highPixelDensity : WindowFlags
highPixelDensity = MkWindowFlags 0x2000
