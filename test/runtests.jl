# put the mock MultiNest library on DL_LOAD_PATH
println("adding $(dirname(@__FILE__())) to DL_LOAD_PATH")
push!(DL_LOAD_PATH, dirname(@__FILE__()))

using MultiNest
using Base.Test

# write your own tests here
@test 1 == 1
