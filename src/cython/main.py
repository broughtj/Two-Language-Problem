from preza.option import Option
from preza.payoff import VanillaCallPayoff, VanillaPutPayoff 
from preza.engine import EuropeanBinomialEngine
from preza.engine import AmericanBinomialEngine
from preza.engine import NaiveMonteCarloEngine
from preza.marketdata import MarketData
from preza.facade import OptionFacade

## Build the options
strike = 40.0
theCall = Option(1.0, VanillaCallPayoff(strike))
thePut = Option(1.0, VanillaPutPayoff(strike))

## Setup up the binomial pricing engine
steps = 1000
reps = 100000
#euroEngine = EuropeanBinomialEngine(steps)
#amerEngine = AmericanBinomialEngine(steps)
mcEngine = NaiveMonteCarloEngine(reps)

## Setup the market data
spot = 41.0
rate = 0.08
vol = 0.30
div = 0.0
theData = MarketData(spot, rate, vol, div)

## Setup up the option facade
#opt1 = OptionFacade(theCall, amerEngine, theData)
#opt2 = OptionFacade(thePut, amerEngine, theData)
#opt1 = OptionFacade(theCall, euroEngine, theData)
#opt2 = OptionFacade(thePut, euroEngine, theData)
opt1 = OptionFacade(theCall, mcEngine, theData)
opt2 = OptionFacade(thePut, mcEngine, theData)



## Price the options
print("The call price is: {0:0.3f}".format(opt1.price()))
print("The put price is: {0:0.3f}".format(opt2.price()))


