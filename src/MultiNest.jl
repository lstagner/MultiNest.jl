module MultiNest

import Base: run

export nested

# find the symbol to invoke MultiNest
# this function opens the MultiNest library, which is kept open to allow
# multiple runs
function nested_symbol()
    # common names for MultiNest library
    names = [ "libmultinest", "libnest3" ]

    # names for library when compiled with MPI support
    names_mpi = [ "libmultinest_mpi", "libnest3_mpi" ]

    # check whether `const MULTINEST_MPI = true` was defined in parent module
    mpi = isdefined(module_parent(current_module()), :MULTINEST_MPI) && module_parent(current_module()).MULTINEST_MPI

    # try find library on DL_LOAD_PATH
    lib = Libdl.find_library(mpi ? names_mpi : names, String[])
    lib == "" && error("cannot find MultiNest library")

    # now open library
    dl = Libdl.dlopen_e(lib)
    dl == C_NULL && error("cannot open MultiNest library")

    # try to find symbol in library
    for sym in [ :__nested_MOD_nestrun, :nested_mp_nestrun_, :nested_mock ]
        (nestrun_ptr = Libdl.dlsym(dl, sym)) != C_NULL && return nestrun_ptr
    end

    # symbol not found
    error("cannot link MultiNest library, check symbol table")
end

# pointer to function that runs MultiNest
const nestrun_ptr = nested_symbol()

# convert to Fortran logical
macro logical(x)
    esc(:(convert(Cint, $x != 0)))
end

# this holds all the information to run MultiNest
immutable Nested
    ins::Cint
    mmodal::Cint
    ceff::Cint
    nlive::Cint
    tol::Cdouble
    efr::Cdouble
    ndim::Cint
    npar::Cint
    nclspar::Cint
    maxmodes::Cint
    updint::Cint
    ztol::Cdouble
    root::String
    seed::Cint
    wrap::Vector{Cint}
    fb::Cint
    resume::Cint
    outfile::Cint
    initmpi::Cint
    logzero::Cdouble
    maxiter::Cint
    loglike::Function
    dumper::Function
    context::Any
end

# interface between MultiNest and Julia loglike function
function nested_loglike(
    cube_::Ptr{Cdouble},
    ndim_::Ptr{Cint},
    npar_::Ptr{Cint},
    lnew_::Ptr{Cdouble},
    nested_::Ptr{Void}
)
    ndim = unsafe_load(ndim_)
    npar = unsafe_load(npar_)
    cube = unsafe_wrap(Array,cube_, npar)
    nested = unsafe_pointer_to_objref(nested_)::Nested
    lnew = nested.loglike(cube, nested.context...)
    unsafe_store!(lnew_, lnew)
    return
end

# interface between MultiNest and Julia dumper function
function nested_dumper(
    nsamples_::Ptr{Cint},
    nlive_::Ptr{Cint},
    npar_::Ptr{Cint},
    physlive_::Ptr{Ptr{Cdouble}},
    posterior_::Ptr{Ptr{Cdouble}},
    paramconstr_::Ptr{Ptr{Cdouble}},
    maxloglike_::Ptr{Cdouble},
    logz_::Ptr{Cdouble},
    inslogz_::Ptr{Cdouble},
    logzerr_::Ptr{Cdouble},
    nested_::Ptr{Void}
)
    nsamples = unsafe_load(nsamples_)
    nlive = unsafe_load(nlive_)
    npar = unsafe_load(npar_)
    physlive = unsafe_wrap(Array,unsafe_load(physlive_), (nlive, Int32(npar+1)))
    posterior = unsafe_wrap(Array,unsafe_load(posterior_), (nsamples, Int32(npar+2)))
    paramconstr = unsafe_wrap(Array,unsafe_load(paramconstr_), (npar, Int32(4)))
    maxloglike = unsafe_load(maxloglike_)
    logz = unsafe_load(logz_)
    inslogz = unsafe_load(inslogz_)
    logzerr = unsafe_load(logzerr_)
    nested = unsafe_pointer_to_objref(nested_)::Nested
    nested.dumper(physlive, posterior, paramconstr, maxloglike, logz, inslogz, logzerr, nested.context...)
    return
end

# default dumper; does nothing
function default_dumper(
    physlive::Array{Cdouble, 2},
    posterior::Array{Cdouble, 2},
    paramconstr::Array{Cdouble, 2},
    maxloglike::Cdouble,
    logz::Cdouble,
    inslogz::Cdouble,
    logzerr::Cdouble,
    context...
)
    # noop
end

# wraparound can be given globally as Bool or as a vector for each dimension
const Wrap = Union{Bool, Vector{Bool}}

# create a Nested object from the various options given
function nested(
    loglike::Function,
    ndim::Integer,
    root::AbstractString;
    ins::Bool = true,
    mmodal::Bool = true,
    ceff::Bool = false,
    nlive::Integer = 1000,
    tol::AbstractFloat = 0.5,
    efr::AbstractFloat = 0.8,
    npar::Integer = ndim,
    nclspar::Integer = npar,
    maxmodes::Integer = 100,
    updint::Integer = 1000,
    ztol::AbstractFloat = -1E90,
    seed::Integer = -1,
    wrap::Wrap = false,
    fb::Bool = true,
    resume::Bool = false,
    outfile::Bool = true,
    initmpi::Bool = true,
    logzero::AbstractFloat = nextfloat(-Inf),
    maxiter::Integer = 0,
    dumper::Function = default_dumper,
    context = ()
    )

    # create root dir if necessary (avoid Fortran runtime error)
    root_dir = dirname(root)
    if !isdir(root_dir)
        mkdir(root_dir)
    end

    # convert arguments to the necessary representation
    ins_c = @logical ins
    mmodal_c = @logical mmodal
    ceff_c = @logical ceff
    root_c = rpad(root, 100, ' ')
    wrap_c = ndims(wrap) == 0 ? [ @logical wrap for i in 1:ndim ] : [ @logical w for w in wrap ]
    fb_c = @logical fb
    resume_c = @logical resume
    outfile_c = @logical outfile
    initmpi_c = @logical initmpi

    # sanity checks
    ndim > 0 || error("ndim must be positive")
    nlive > 0 || error("nlive must be positive")
    tol > 0 || error("tol must be positive")
    0 < efr <= 1 || error("efr must be in (0, 1]")
    npar >= ndim || error("npar must be greater than or equal to ndim")
    nclspar <= npar || error("nclspar must be less than or equal to npar")
    maxmodes > 0 || error("maxmodes must be positive")
    updint > 0 || error("updint must be positive")
    size(wrap_c) == (ndim,) || error("size of wrap does not match ndim")
    maxiter >= 0 || error("maxiter must be positive or zero for no maximum")

    # create Nested object
    Nested(ins_c, mmodal_c, ceff_c, nlive, tol, efr, ndim, npar, nclspar,
           maxmodes, updint, ztol, root_c, seed, wrap_c, fb_c, resume_c,
           outfile_c, initmpi_c, logzero, maxiter, loglike, dumper, context)
end

# run MultiNest
@eval begin
    function run(n::Nested)
        loglike_c = cfunction(nested_loglike, Void, (
            Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Void}
        ))

        dumper_c = cfunction(nested_dumper, Void, (
            Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Ptr{Cdouble}},
            Ptr{Ptr{Cdouble}}, Ptr{Ptr{Cdouble}}, Ptr{Cdouble},
            Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Void}
        ))

        ccall($nestrun_ptr, Void, ( Ref{Cint}, Ref{Cint}, Ref{Cint},
              Ref{Cint}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cint}, Ref{Cint},
              Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cdouble}, Ptr{UInt8},
              Ref{Cint}, Ptr{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint},
              Ref{Cdouble}, Ref{Cint}, Ptr{Void}, Ptr{Void}, Any ),
              n.ins, n.mmodal, n.ceff, n.nlive, n.tol, n.efr,
              n.ndim, n.npar, n.nclspar, n.maxmodes, n.updint, n.ztol,
              n.root, n.seed, n.wrap, n.fb, n.resume, n.outfile, n.initmpi,
              n.logzero, n.maxiter, loglike_c, dumper_c, n)
    end
end

end
