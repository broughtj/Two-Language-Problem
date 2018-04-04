# cython: nonecheck=True
# cython: boundscheck=False
# cython: cdivision=True


import numpy as np
cimport numpy as np
from scipy.stats import binom

cdef class PricingEngine:
    """
    A base class for option pricing engines.
    """

    cdef double calculate(self, Option option, MarketData data):
        pass


cdef class BinomialEngine(PricingEngine):
    """
    An interface class for binomial pricing engines.
    """

    def __init__(self, nsteps):
        self._nsteps = nsteps

    cdef double calculate(self, Option option, MarketData data):
        pass


cdef class EuropeanBinomialEngine(BinomialEngine):
    """
    A concrete class for the European binomial option pricing model.
    """

    cdef double calculate(self, Option option, MarketData data):
        cdef double expiry = option.expiry
        cdef double strike = option.strike
        cdef double spot = data.spot
        cdef double rate = data.rate
        cdef double vol = data.vol
        cdef double div = data.div
        cdef double dt = expiry / self._nsteps
        cdef double u = cexp(((rate - div) * dt) + vol * csqrt(dt))
        cdef double d = cexp(((rate - div) * dt) - vol * csqrt(dt))
        cdef double pu = (cexp((rate - div) * dt) - d) / (u - d)
        cdef double pd = 1.0 - pu
        cdef double df = cexp(-rate * expiry)
        cdef double spot_t = 0.0
        cdef double payoff_t = 0.0
        cdef unsigned long nodes = self._nsteps + 1
        cdef unsigned long i

        for i in range(nodes):
            spot_t = spot * (u ** (self._nsteps - i)) * (d ** i)
            payoff_t += option.payoff(spot_t) * dbinom(self._nsteps - i, self._nsteps, pu)

        return df * payoff_t


cdef class AmericanBinomialEngine(BinomialEngine):
    """
    A concrete class for the American binomial option pricing model.
    """

    cdef double calculate(self, Option option, MarketData data):
        cdef double dt = option.expiry / self._nsteps
        cdef double u = np.exp((data.rate - data.div) * dt + data.vol * np.sqrt(dt))
        cdef double d = np.exp((data.rate - data.div) * dt - data.vol * np.sqrt(dt))
        cdef double pu = (np.exp((data.rate - data.div) * dt) - d) / (u - d)
        cdef double pd = 1.0 - pu
        cdef double disc = np.exp(-data.rate * dt)
        cdef double dpu = disc * pu
        cdef double dpd = disc * pd
        cdef long num_nodes = self._nsteps + 1

        cdef double[::1] spot_t = np.zeros(num_nodes, dtype=np.float64)
        cdef double[::1] call_t = np.zeros(num_nodes, dtype=np.float64)

        cdef long i, j

        for i in range(num_nodes):
            spot_t[i] = data.spot * cpow(u, self._nsteps - i) * cpow(d, i)
            call_t[i] = option.payoff(spot_t[i])

        for i in range(self._nsteps - 1, -1, -1):
            for j in range(i + 1):
                call_t[j] = dpu * call_t[j] + dpd * call_t[j+1]
                spot_t[j] = spot_t[j] / u
                call_t[j] = np.maximum(call_t[j], option.payoff(spot_t[j]))

        return call_t[0]


cdef class MonteCarloEngine(PricingEngine):
    """
    An interface class for Monte Carlo pricing engines.
    """

    def __init__(self, nreps):
        self._nreps = nreps

    cdef double calculate(self, Option option, MarketData data):
        pass


cdef class NaiveMonteCarloEngine(MonteCarloEngine):
    """
    A concrete class for a Naive Monte Carlo pricing engine.
    """

    cdef double calculate(self, Option option, MarketData data):
        cdef double dt = option.expiry 
        cdef double rate = data.rate
        cdef double spot = data.spot
        cdef double vol = data.vol
        cdef double div = data.div
        cdef unsigned int seed = np.random.randint(low=1,high=100000, size=1)[0]
        cdef double[::1] z = rnorm(self._nreps, seed, 0.0, 1.0) 
        cdef double[::1] spot_t = np.empty(self._nreps, dtype=np.float64)
        cdef double[::1] payoff_t = np.empty(self._nreps, dtype=np.float64)
        cdef double disc = cexp(-(rate - div) * dt)
        cdef double nudt = (rate - div - 0.5 * vol * vol) * dt
        cdef double sigdt = vol * csqrt(dt)

        for i in range(self._nreps):
            spot_t[i] = spot * cexp(nudt + sigdt * z[i])
            payoff_t[i] = option.payoff(spot_t[i])

        cdef double price = np.mean(payoff_t) * disc

        return price




