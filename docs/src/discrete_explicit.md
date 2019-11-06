# Discrete Explicit Interface

The Discrete Explicit Interface is designed to match the standard definition of a POMDP in the literature as closely as possible. The standard definition uses the tuple (S,A,O,T,Z,R,γ) for a POMDP and (S,A,T,R,γ) for an MDP, where

- S, A, and O are the state, action, and observation spaces,
- T and Z are the transition and observation probability distribution functions (pdfs),
- R is the reward function, and
- γ is the discount factor.

The `DiscreteExplicitPOMDP` and `DiscreteExplicitMDP` types are provided for POMDPs and MDPs with discrete spaces and explicitly defined distributions. They should offer moderately good performance on small to medium-sized problems. Instructions for defining the **initial distribution** and **terminal states** can be found in the docstrings.

## Example

The classic tiger POMDP \[[Kaelbling et al. 98](http://www.sciencedirect.com/science/article/pii/S000437029800023X)\] can be defined as follows:

```jldoctest; output = false
using QuickPOMDPs

S = [:left, :right]           # S, A, and O may contain any objects
A = [:left, :right, :listen]  # including user-defined types
O = [:left, :right]
γ = 0.95

function T(s, a, sp)
    if a == :listen
        return s == sp
    else # a door is opened
        return 0.5 #reset
    end
end

function Z(a, sp, o)
    if a == :listen
        if o == sp
            return 0.85
        else
            return 0.15
        end
    else
        return 0.5
    end
end

function R(s, a)
    if a == :listen  
        return -1.0
    elseif s == a # the tiger was found
        return -100.0
    else # the tiger was escaped
        return 10.0
    end
end

m = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ)

# output

DiscreteExplicitPOMDP{Symbol,Symbol,Symbol,typeof(Z),typeof(R),POMDPModelTools.Uniform{Set{Symbol}}}(Symbol[:left, :right], Symbol[:left, :right, :listen], Symbol[:left, :right], Dict((:left, :right) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:left, :listen) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left], [1.0]),(:right, :left) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:right, :right) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:right, :listen) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:right], [1.0]),(:left, :left) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5])), Dict((:listen, :right) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.15, 0.85]),(:left, :right) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:right, :left) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:right, :right) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5]),(:listen, :left) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.85, 0.15]),(:left, :left) => POMDPModelTools.SparseCat{Array{Symbol,1},Array{Float64,1}}(Symbol[:left, :right], [0.5, 0.5])), Z, R, Dict(:left => 1,:right => 2), Dict(:left => 1,:right => 2,:listen => 3), Dict(:left => 1,:right => 2), 0.95, POMDPModelTools.Uniform{Set{Symbol}}(Set(Symbol[:left, :right])), Set(Symbol[]))
```

## Constructor Documentation

```@docs
DiscreteExplicitMDP
DiscreteExplicitPOMDP
```

## Usage from Python

The Discrete Explicit interface can be used from python via [pyjulia](https://github.com/JuliaPy/pyjulia). See [examples/tiger.py](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/tiger.py) for an example.
