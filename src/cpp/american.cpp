/*
*/
#include <random>
#include <cassert>
#include <math.h>
#include <vector>
#include <algorithm>
#include <iostream>
#include <time.h>
#include <cmath>
#include <stdlib.h>

//#include "Binomial.hpp"

double choose(double n, double k)
{
  int i;
  int mn;
  int mx;
  double value;

  if(k < n - k)
  {
    mn = k;
    mx = n - k;
  }
  else
  {
    mn = n - k;
    mx = k;
  }

  if(mn < 0)
  {
    value = 0.0;
  }
  else if(mn == 0)
  {
    value = 1.0;
  }
  else
  {
    value = static_cast<double>(mx + 1);

    for (i = 2; i <= mn; i++)
    {
      value = (value * static_cast<double>(mx + i)) / static_cast<double>(i);
    }
  }
  
  return value;
}

double dbinom(double x, double n, double p)
{
  double value;

  if(x < 0.0)
  {
    value = 0.0;
  }
  else if(x <= n)
  {
    value = choose(n, x) * pow (p, x) * pow (1.0 - p, n - x);
  }
  else
  {
    value = 0.0;
  }

  return value;
}

struct Data{
	double spot;
	double rate;
	double volatitlity;
	double dividend;
	Data(double s, double r, double v, double d){
		spot = s;
		rate = r;
		volatitlity = v;
		dividend = d;
	}
};

class Payoff{
public:
	Payoff(double s){
		strike = s;
	}

	virtual double CalcPayoff(double) = 0;

protected:
	double strike;

};

class VanillaCall: virtual public Payoff{
public:
	VanillaCall(double s)
		:Payoff(s){}

	double CalcPayoff(double spot){
		return std::max(spot-strike, 0.0);
	}
};

class VanillaPut: virtual public Payoff{
public:
	VanillaPut(double s)
		: Payoff(s){}

	double CalcPayoff(double spot){
		return std::max(strike-spot, 0.0);
	}
};


class Option{
public:
	Option(double s, double e, Payoff* p){
		strike = s;
		expiry = e;
		payoff = p;
	};

	double strike;
	double expiry;
	Payoff* payoff;
};

class EuropeanBinomialEngine{
public:

	EuropeanBinomialEngine(int step){
		_step = step;
	}

	double Calculate(Data data, Option option){
		double dt = option.expiry/_step;
		double u = exp(((data.rate - data.dividend)*dt) + data.volatitlity*sqrt(dt));
		double d = exp(((data.rate - data.dividend)*dt) - data.volatitlity*sqrt(dt));
		double pu = (exp((data.rate - data.dividend) * dt) - d) / (u - d);
		double pd = 1.0 - pu;
		double df = exp(-data.rate * option.expiry);
		double spot_t = 0.0;
		double payoff_t = 0.0;
		long nodes = _step + 1;

		for(long i = 0; i < nodes; ++i){
			spot_t = data.spot * pow(u, _step-i) * pow(d, i);
			payoff_t += option.payoff->CalcPayoff(spot_t) * dbinom(_step-i, _step, pu);//this is where the dbinom()goes
		}
		return df*payoff_t;
	}

private:
	int _step;
};


class AmericanBinomialEngine{
public:

	AmericanBinomialEngine(int step){
		_steps = step;
	}

	double Calculate(Data data, Option option){

		double dt = option.expiry/_steps;
		double u  = exp((data.rate - data.dividend) * dt + data.volatitlity*sqrt(dt));	//where is this coming from?
		double d  = exp((data.rate - data.dividend) * dt - data.volatitlity*sqrt(dt));
		double pu = (exp((data.rate - data.dividend) * dt) - d) / (u - d);
		double pd = 1 - pu;
		double disc = exp(-data.rate * dt);
		double dpu = disc * pu;
		double dpd = disc * pd;
		long num_nodes = _steps + 1;

		std::vector<double> spot_t(num_nodes);
		std::vector<double> call_t(num_nodes);

		for(int i = 0; i < num_nodes; ++i){
			spot_t[i] = data.spot * pow(u, _steps-i) * pow(d, i); //what is this doing? why steps-i, and for the other 
			call_t[i] = option.payoff->CalcPayoff(spot_t[i]);	//need to modify in order to use option.payoff.CalcPayoff
		}

		for(int i = _steps-1; i >= 0; --i){
			for(int j = 0; j < i+1; ++j){
				call_t[j] = dpu * call_t[j] + dpd * call_t[j+1];
				spot_t[j] = spot_t[j] / u;
			}
		}
		
		return call_t[0];
	}

private:
	int _steps;
};

class MonteCarloEngine{
public:
	MonteCarloEngine(int reps){
		_nreps = reps;
	}

	double Calculate(Data data, Option option){
		double dt = option.expiry;
		double rate = data.rate;
		double spot = data.spot;
		double vol = data.volatitlity;
		double div = data.dividend;

		//the random number generators.... still don't know what it's talking about
		std::random_device rd{};
		std::mt19937 engine{rd()};
		std::normal_distribution<double> distribution{0.0,1.0};

		double z[_nreps];
		double spot_t[_nreps];
		double payoff_t[_nreps];
		double disc = exp(-(rate - div) * dt);
		double nudt = (rate - div - 0.5 * vol * vol) * dt;
		double sigdt = vol * sqrt(dt);

		for(int i = 0; i < _nreps; ++i){
			double num = distribution(engine);
			spot_t[i] = spot * exp(nudt + sigdt * num);
			payoff_t[i] = option.payoff->CalcPayoff(spot_t[i]);
		}

		double total=0;
		for(int j = 0; j < _nreps; ++j){
			total+=payoff_t[j];
		}
		double price = (total/_nreps)*disc;
		return price;
	}

private:
	int _nreps;
};



int main(void){
	double strike = 40;
	double call; //will be equal to the return of Option with call payoff
	double put;  //put payoff

	//parameters: spot, rate, volatility, dividend
	Data data(41, .08, .3, 0);

	//parameters: strike
	Payoff * vanCall = new VanillaCall(strike);
	Payoff * vanPut  = new VanillaPut(strike); 

	Option optionCall(40, 1, vanCall);
	Option optionPut(40, 1, vanPut);

	//EuropeanBinomial Tester
	EuropeanBinomialEngine euroCall(100);
	std::cout << "EuropeanBinomial Call and Put:\n";
	std::cout << euroCall.Calculate(data,optionCall) << std::endl;
	std::cout << euroCall.Calculate(data,optionPut) << std::endl;

	//AmericanBinomial Tester
	AmericanBinomialEngine amerCall(100);
	std::cout << "AmericanBinomial Call and Put:\n";
	std::cout << amerCall.Calculate(data, optionCall) << std::endl;
	std::cout << amerCall.Calculate(data, optionPut) << std::endl;
	 
	//MonteCartos Tester
	MonteCarloEngine monte(100000);
	std::cout << "MonteCarlo Call and Put:\n";
	std::cout << monte.Calculate(data, optionCall) << std::endl;
	std::cout << monte.Calculate(data, optionPut) << std::endl;
	

	return 0;
}



