#include <cmath>
#include "Binomial.hpp"

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

