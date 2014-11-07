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

Since MultiNest, even though bundled as a library, is virtually an external
command, the MultiNest.jl package follows the semantics of Julia's built-in
external commands.

The `MultiNest` module can be loaded into Julia with

```julia
using MultiNest
```

It exports a single function new function, `nested()`, that will create a
MultiNest configuation. Like other external commands, it can subsequently be
invoked with Julia's `run()` function.

In it's purest form, `nested()` is called with the log-likelihood function you
want to investigate, the dimension of the parameter space, and the output root:

```julia
using MultiNest

# define loglike
# ...

# generate MultiNest call
nest = nested(loglike, 2, "chains/example-")

# run MultiNest
run(nest)
```

All of MultiNest's additional options can be passed to `nested()` as keyword
arguments. Please see the classical [eggbox example](examples/eggbox.jl) for
more information.

It is possible to pass additional arguments to your log-likelihood and dumper
functions. See the [eggbox with context example](examples/eggbox_context.jl)
for more information on context passing.

If Julia cannot find the MultiNest libraries by default, you can make their
location known as follows:

```julia
# make library location known
push!(DL_LOAD_PATH, "/path/to/MultiNest")

# now load MultiNest module
using MultiNest
```
