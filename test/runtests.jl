# build the mock dynamic library
run(`make`)

# put the mock MultiNest library on DL_LOAD_PATH
push!(DL_LOAD_PATH, dirname(@__FILE__()))

using MultiNest
using Base.Test

# write your own tests here
@test 1 == 1

# done with tests, clean up
run(`make clean`)
