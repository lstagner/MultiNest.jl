using MultiNest



##### loglikelihood routine #####

# sample an egg box likelihood
# 
# arguments
# cube 
#     on entry has the ndim parameters in unit-hypercube
#     on exit, the ndim physical parameters plus (npar-ndim) derived parameters
#     you want to store with the free parameters
# 
# returns
# log-likelihood

function loglike(cube::Vector{Cdouble})
    chi = 1.0
    for i in 1:length(cube)
        x = cube[i]*10pi
        chi *= cos(0.5x)
        cube[i] = x
    end
    (chi + 2)^5
end

#####



##### dumper routine #####

# The dumper routine will be called every updInt*10 iterations
# MultiNest does not need to the user to do anything. User can use the arguments
# in whichever way he/she wants
# 
# arguments:
#
# physlive[nlive, npar + 1]
#     2D array containing the last set of live points (physical parameters plus
#     derived parameters) along with their log-likelihood values
# posterior[nsamples, npar + 2]
#     posterior distribution containing nSamples points. Each sample has npar
#     parameters (physical + derived) along with the their loglike value &
#     posterior probability
# paramConstr[npar, 4]
#     for each parameter, an array of [ mean, stddev, ML, MAP ] values
# maxloglike
#     maximum log-likelihood value
# logz
#     log evidence value from the default (non-INS) mode
# inslogz
#     log evidence value from the INS mode
# logzerr
#     error on log evidence value
function dumper(
    physlive::Array{Cdouble, 2},
    posterior::Array{Cdouble, 2},
    paramconstr::Array{Cdouble, 2},
    maxloglike::Cdouble,
    logz::Cdouble,
    inslogz::Cdouble,
    logzerr::Cdouble
)
    println("dumper called after ", size(posterior, 1), " samples")
end


#####



##### main program #####

# create MultiNest configuration
# arguments are log-likelihood function, number of dimensions, output root
# other MultiNest parameters are given as keywords and can be omitted
nest = nested(loglike, 2, "chains/eggbox_jl-",
    ins = true,
    mmodal = false,
    ceff = false,
    nlive = 1000,
    efr = 1.0,
    tol = 0.1,
    npar = 2,
    nclspar = 2,
    updint = 1000,
    ztol = -1E90,
    maxmodes = 100,
    wrap = false,
    seed = -1,
    fb = true,
    resume = false,
    outfile = true,
    initmpi = true,
    logzero = nextfloat(-Inf),
    maxiter = 0,
    dumper = dumper
)

# run MultiNest
@time run(nest)

#####
