module QuickPOMDPs

using POMDPs
using POMDPTools
using UUIDs
using NamedTupleTools
using Random
using Tricks: static_hasmethod

export
    DiscreteExplicitPOMDP,
    DiscreteExplicitMDP,
    QuickMDP,
    QuickPOMDP,
    MissingQuickArgument

include("discrete_explicit.jl")
include("quick.jl")
include("quick_error.jl")

end # module
