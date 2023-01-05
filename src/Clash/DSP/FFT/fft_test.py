




from clash_testbench import Testbench, Chronogram, Signal
from os.path import dirname, join
import numpy as np


filepath = join(dirname(__file__), './fft_test.hs')
def test_fft():

    tb = Testbench(filepath, 'fft_test', verbose=True)

    cg = Chronogram()
    
    N = 16//2

    inputData = np.tile([1+1j, 0.5+0.707j, 0.9+1j, 1 + 0j], 4)

    pairedInput = [f"(({x[0].real},{x[0].imag}),({x[1].real},{x[1].imag}))" for x in inputData.reshape(-1,2)]

    en = Signal('enable', 3*[0] + N*[1])
    inp = Signal('input', 3*['((1.0,0.0),(1.0,0.0))'] + pairedInput)

    tb.setInputs([
        en,
        inp
    ])

    tb.setExpectedOutputs([
        None
    ])
    tb.setActualOutputsNames([
        'a'
    ])

    tb.run()

    cg = Chronogram()
    cg.setSignals(tb.getAllSignals())

    cg.saveSVG('fft_test.svg')



    
