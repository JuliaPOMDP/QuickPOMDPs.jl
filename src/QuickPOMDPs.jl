module QuickPOMDPs

using POMDPs
using POMDPModelTools
using BeliefUpdaters
using POMDPTesting
using UUIDs
using NamedTupleTools

export
    DiscreteExplicitPOMDP,
    DiscreteExplicitMDP,
    QuickMDP

include("discrete_explicit.jl")
include("quick.jl")

end # module
