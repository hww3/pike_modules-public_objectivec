#define OCAC(X, Y) do{struct svalue * _sv; _sv = id_to_svalue(X); simple_add_constant(Y, _sv, 0); free(_sv);} while(0);
