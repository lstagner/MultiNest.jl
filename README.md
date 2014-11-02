MultiNest.jl
============

[MultiNest](http://ccpforge.cse.rl.ac.uk/gf/project/multinest/) wrapper for the
[Julia](http://julialang.org) language.

[![Build Status](https://travis-ci.org/ntessore/MultiNest.jl.svg)](https://travis-ci.org/ntessore/MultiNest.jl)

Installation
------------

The package does not contain MultiNest itself (as you need to register before
you can obtain a copy), so you will need to download and build *shared* 
MultiNest libraries separately.

Afterwards, you can get a copy of `MultiNest.jl` by cloning it from Julia's
package manager:

```julia
Pkg.clone("https://github.com/ntessore/MultiNest.jl.git")
```

Usage
-----

The `MultiNest` package can be loaded into Julia with

```julia
using MultiNest
```

The `MultiNest` module exports a single function call `nested()` that will run
the MultiNest algorithm for you. In it's purest form, `nested()` is invoked with
the log-likelihood function you want to investigate, the dimension of the
parameter space, and the root for output:

```julia
using MultiNest

# define loglike
# ...

nested(loglike, 2, "chains/example-")
```

All of MultiNest's options can be passed as keyword arguments. Please see the
classical [eggbox example](examples/eggbox.jl) for more information. There is
also an [eggbox with context example](examples/eggbox_context.jl) that shows
how to pass custom context arguments to the log-likelihood and dumper functions.

If Julia cannot find the MultiNest libraries by default, you can make their
location known as follows:

```julia
# make library location known
push!(DL_LOAD_PATH, "/path/to/MultiNest")

# now load MultiNest module
using MultiNest
```
