module Clash.DSP.FFT.FFT_test where

import Clash.Prelude
import Clash.DSP.Complex
import Clash.DSP.FFT.Example
import Clash.DSP.FFT.Twiddle (twiddleFactors)

type MFixed = SFixed 2 14
type IQ = (MFixed, MFixed)

fft_test
    :: forall dom . (HiddenClockResetEnable dom)
    => Signal dom Bit -- Enable
    -> Signal dom (IQ, IQ) -- Input sample
    -> Signal dom (IQ, IQ) -- Output sample
fft_test en input = output
  where
    -- ok
    twiddles :: Vec 4 (Complex MFixed)
    twiddles = $(listToVecTH (twiddleFactors 4))

    --output = pure ((0.0, 0.0),(0.0, 0.0))

    (a, b) = unbundle input

    toCplx :: IQ -> Complex MFixed
    toCplx (a, b) = a :+ b

    fromCplx :: Complex MFixed -> IQ
    fromCplx (a :+ b) = (a, b)

    -- complex :: Signal dom (Complex MFixed)
    -- complex = toCplx <$> input

    fftInput' :: Signal dom (Complex MFixed, Complex MFixed)
    fftInput' = bundle (toCplx <$> a, toCplx <$> b)

    -- fftInput :: Signal dom (Complex MFixed, Complex MFixed)
    -- fftInput = pure (0.0 :+ 0.0, 0.0 :+0.0)
    
    -- split :: Maybe a -> (Bool, a)
    -- split a =
    --   ( isJust a
    --   , fromMaybe (errorX "split: Nothing") )


    fftOutput :: Signal dom (Complex MFixed, Complex MFixed)
    --fftOutput = fftSerialDIF twiddles (bitToBool <$> en) fftInput'
    fftOutput = fftSerialDIT twiddles (bitToBool <$> en) fftInput'

    (aout, bout) = unbundle fftOutput

    output = bundle (fromCplx <$> aout, fromCplx <$> bout)

