/* mock library for testing MultiNest.jl */

typedef void (*loglike)(double*, int*, int*, double*, void*);
typedef void (*dumper)(int*, int*, int*, double**, double**, double**, double*, double*, double*, double*, void*);

void nested_mock(int* ins, int* mmodal, int* ceff, int* nlive, double* tol,
    double* efr, int* ndim, int* npar, int* nclspar, int* maxmodes, int* updint,
    double* ztol, char* root, int* seed, int* wrap, int* fb, int* resume,
    int* outfile, int* initmpi, double* logzero, int* maxiter, loglike l,
    dumper d, void* context)
{
}
