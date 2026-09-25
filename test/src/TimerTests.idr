module TimerTests

import SDL3

%default covering

units : IO (Either String ())
units = do
  before <- ticks
  ns <- ticksNS
  after <- ticks
  frequency <- performanceFrequency
  again <- performanceFrequency
  if ns `div` 1000000 < before || ns `div` 1000000 > after
     then pure (Left "Nanosecond and millisecond timer units disagree")
     else if frequency == 0 || frequency /= again
             then pure (Left "Performance counter frequency is zero or unstable")
             else pure (Right ())

waitCase : (Bits64 -> IO ()) -> Bits64 -> IO (Either String ())
waitCase wait minimum = do
  start <- ticksNS
  counterStart <- performanceCounter
  wait 1000000
  counterEnd <- performanceCounter
  end <- ticksNS
  -- No upper bound: the operating system can resume this thread late.
  if end <= start || counterEnd <= counterStart
     then pure (Left "High-resolution timers did not advance during a delay")
     else if end - start < minimum
             then pure (Left "Nanosecond delay returned before the requested interval")
             else pure (Right ())

export
timerTests : IO (Either String ())
timerTests = do
  delayNS 0
  delayPrecise 0
  Right () <- units | Left err => pure (Left err)
  Right () <- waitCase delayNS 1000000 | Left err => pure (Left err)
  -- Precise delay attempts the requested interval, without an exact-time guarantee.
  waitCase delayPrecise 0
