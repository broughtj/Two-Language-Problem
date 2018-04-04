## binomial.make
#

main:		main.o Binomial.o
		g++ -o main main.o Binomial.o

main.o:	        main.cpp Binomial.cpp
	        g++ -c main.cpp

Binomial.o:	Binomial.cpp Binomial.hpp
	        g++ -c Binomial.cpp

clean:
	        rm -f *.o main
