# QuickPOMDPs

[![Build Status](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaPOMDP/QuickPOMDPs.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaPOMDP/QuickPOMDPs.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl?branch=master)

Simplified Interface for specifying [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) models.

For now there is only one interface (Discrete Explicit), but more may be added (see [IDEAS.md](IDEAS.md)).

## Discrete Explicit Interface

This interface is designed to match the standard definition of a POMDP in the literature as closely as possible. The standard definition uses the tuple (S,A,O,T,Z,R,γ) for a POMDP and (S,A,T,R,γ) for an MDP, where

- S, A, and O are the state, action, and observation spaces,
- T and Z are the transition and observation probability distribution functions (pdfs),
- R is the reward function, and
- γ is the discount factor.

The `DiscreteExplicitPOMDP` and `DiscreteExplicitMDP` types are provided for POMDPs and MDPs with discrete spaces and explicitly defined distributions. They should offer moderately good performance on small to medium-sized problems. Instructions for defining the **initial distribution** and **terminal states** can be found in the docstrings.

### Example

The classic tiger POMDP \[[Kaelbling et al. 98](http://www.sciencedirect.com/science/article/pii/S000437029800023X)\] can be defined as follows:

```julia
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
```
