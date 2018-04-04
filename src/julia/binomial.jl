using Distributions

abstract type Option end
abstract type VanillaOption <: Option end
abstract type EuropeanVanillaOption <: VanillaOption end
abstract type AmericanVanillaOption <: VanillaOption end

type EuropeanCall <: EuropeanVanillaOption
	strike::Float64
	expiry::Float64
end


type AmericanCall <: AmericanVanillaOption 
	strike::Float64
	expiry::Float64
end


function payoff(option::EuropeanCall, spot::Float64)
	return max(spot - option.strike, 0.0)
end


function payoff(option::AmericanCall, spot::Float64)
	return max(spot - option.strike, 0.0)
end

#=
type PutOption <: VanillaOption
	strike::Float64
	expiry::Float64
	style::EXERCISETYPE
end


function payoff(option::PutOption, spot::Float64)
	return max(option.strike - spot, 0.0)
end
=#

type MarketData
	spot::Float64
	rate::Float64
	volatility::Float64
	dividend::Float64
end


function BinomialPricer(option::EuropeanVanillaOption, data::MarketData, steps::Int)
	nodes = steps + 1
	dt = option.expiry / steps 
	u = exp((data.rate - data.dividend) * dt + data.volatility * sqrt(dt))
	d = exp((data.rate - data.dividend) * dt - data.volatility * sqrt(dt))
	pstar = (exp((data.rate - data.dividend)*dt) - d) / (u - d) 
	rnd = Binomial(steps, pstar)
	prc = 0.0
		
	for i = 1:nodes
		spot = data.spot * (u^(i - 1)) * (d^(nodes - i))
		prc += payoff(option, spot) * pdf(rnd, i - 1)
	end

	prc *= exp(-(data.rate - data.dividend) * option.expiry)

	return prc
end


function BinomialPricer(option::AmericanVanillaOption, data::MarketData, steps::Int64)
	nodes = steps + 1
	dt = option.expiry / steps 
	u = exp((data.rate - data.dividend) * dt + data.volatility * sqrt(dt))
	d = exp((data.rate - data.dividend) * dt - data.volatility * sqrt(dt))
	pu = (exp((data.rate - data.dividend)*dt) - d) / (u - d) 
	pd = 1 - pu
	disc = exp(-data.rate * dt)
	dpu = disc * pu 
	dpd = disc * pd 
	rnd = Binomial(steps, pu)
	prc = 0.0	
	spot_t = zeros(nodes)
	call_t = zeros(nodes)

	for i = 1:nodes
		spot_t[i] = data.spot * (u^(i - 1)) * (d^(nodes - i))
		call_t[i] = payoff(option, spot_t[i]) * pdf(rnd, i - 1)
	end

	for i = (nodes - 1):-1:1
		for j = 1:i
			call_t[j] = dpu * call_t[j] + dpd * call_t[j+1]
			spot_t[j] = spot_t[j] / u
			call_t[j] = max(call_t[j], payoff(option, spot_t[j]))
		end
	end

	return call_t[1]
end


function main()
	spot = 41.0
	strike = 40.0
	rate = 0.08
	vol = 0.30
	div = 0.0
	expiry = 1.0
	steps = 3

	data = MarketData(spot, rate, vol, div)
	call1 = EuropeanCall(strike, expiry)
	call2 = AmericanCall(strike, expiry)
	callPrc1 = round(BinomialPricer(call1, data, steps), 2)
	callPrc2 = round(BinomialPricer(call2, data, steps), 2)

	println("The European Call Price is: \$$callPrc1")
	println("The American Call Price is: \$$callPrc2")
end
