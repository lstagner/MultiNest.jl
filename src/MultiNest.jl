module MultiNest

export nested

# find the MultiNest library
function nested_library()
    names = [ "libmultinest", "libnest3" ]
    names_mpi = [ "libmultinest_mpi", "libnest3_mpi" ]
    mpi = isdefined(module_parent(current_module()), :MULTINEST_MPI) && module_parent(current_module()).MULTINEST_MPI
    lib = find_library(mpi ? names_mpi : names, ASCIIString[])
    lib == "" && error("cannot find MultiNest library")
    lib
end

# find the symbol to invoke MultiNest
function nested_symbol()
    nestdl = dlopen_e(libmultinest)
    nestdl == C_NULL && error("cannot open MultiNest library")
    for sym in [ :__nested_MOD_nestrun, :nested_mp_nestrun_, :nested_mock ]
        dlsym_e(nestdl, sym) != C_NULL && (dlclose(nestdl); return sym)
    end
    dlclose(nestdl)
    error("cannot link MultiNest library, check symbol table")
end

# MultiNest library
const libmultinest = nested_library()

# symbol that runs MultiNest
const nestrun = nested_symbol()

# convert to Fortran logical
logical(x) = bool(x) ? Cint(1) : Cint(0)

function nested_loglike(
    cube_::Ptr{Cdouble},
    ndim_::Ptr{Cint},
    npar_::Ptr{Cint},
    lnew_::Ptr{Cdouble},
    context_::Ptr{Void}
)
    ndim = unsafe_load(ndim_)
    npar = unsafe_load(npar_)
    cube = pointer_to_array(cube_, npar)
    context = unsafe_pointer_to_objref(context_)::Context
    lnew = context.loglike(cube, context.context...)
    unsafe_store!(lnew_, lnew)
    return nothing
end

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
    context_::Ptr{Void}
)
    nsamples = unsafe_load(nsamples_)
    nlive = unsafe_load(nlive_)
    npar = unsafe_load(npar_)
    physlive = pointer_to_array(unsafe_load(physlive_), (nlive, npar+1))
    posterior = pointer_to_array(unsafe_load(posterior_), (nsamples, npar+2))
    paramconstr = pointer_to_array(unsafe_load(paramconstr_), (npar, 4))
    maxloglike = unsafe_load(maxloglike_)
    logz = unsafe_load(logz_)
    inslogz = unsafe_load(inslogz_)
    logzerr = unsafe_load(logzerr_)
    context = unsafe_pointer_to_objref(context_)::Context
    context.dumper(physlive, posterior, paramconstr, maxloglike, logz, inslogz, logzerr, context.context...)
    return nothing
end

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

immutable Context
    loglike::Function
    dumper::Function
    context
end

@eval begin
    function nested(
        loglike::Function,
        ndim::Integer,
        root::String;
        ins = true,
        mmodal = true,
        ceff = false,
        nlive = 1000,
        tol = 0.5,
        efr = 0.8,
        npar = ndim,
        nclspar = npar,
        maxmodes = 100,
        updint = 1000,
        ztol = -1E90,
        seed = -1,
        wrap = false,
        fb = true,
        resume = false,
        outfile = true,
        initmpi = true,
        logzero = nextfloat(-Inf),
        maxiter = 0,
        dumper::Function = default_dumper,
        context = ()
    )
        ins_c = logical(ins)
        mmodal_c = logical(mmodal)
        ceff_c = logical(ceff)
        root_c = rpad(root, 100, ' ')
        wrap_c = ndims(wrap) == 0 ? fill(logical(wrap), ndim) : map(logical, wrap)
        fb_c = logical(fb)
        resume_c = logical(resume)
        outfile_c = logical(outfile)
        initmpi_c = logical(initmpi)
        
        loglike_c = cfunction(nested_loglike, Void, (
            Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Void}
        ))
        
        dumper_c = cfunction(nested_dumper, Void, (
            Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Ptr{Cdouble}},
            Ptr{Ptr{Cdouble}}, Ptr{Ptr{Cdouble}}, Ptr{Cdouble},
            Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Cdouble}, Ptr{Void}
        ))
        
        context_c = Context(loglike, dumper, context)
        
        ccall(($(string(nestrun)), libmultinest), Void,
            ( Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble},
            Ptr{Cdouble}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint},
            Ptr{Cint}, Ptr{Cdouble}, Ptr{Uint8}, Ptr{Cint}, Ptr{Cint},
            Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble},
            Ptr{Cint}, Ptr{Void}, Ptr{Void}, Any ),
            &ins_c, &mmodal_c, &ceff_c, &nlive, &tol, &efr, &ndim, &npar,
            &nclspar, &maxmodes, &updint, &ztol, root_c, &seed,
            pointer(wrap_c), &fb_c, &resume_c, &outfile_c, &initmpi_c,
            &logzero, &maxiter, loglike_c, dumper_c, context_c
        )
    end
end

end
