# QuickPOMDPs

[![Build Status](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl)
[![Docs - Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaPOMDP.github.io/QuickPOMDPs.jl/stable)
[![Docs - Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPOMDP.github.io/QuickPOMDPs.jl/dev)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl?branch=master)

Simplified interfaces for specifying [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) models.

The package contains two interfaces - the Quick interface, and the Discrete Explicit interface.

**Please see [the documentation](https://JuliaPOMDP.github.io/QuickPOMDPs.jl/stable) for more information on each.**

The package can also be used from **[Python](https://www.python.org)** via [pyjulia](https://github.com/JuliaPy/pyjulia). See [examples/tiger.py](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/tiger.py) for an example.

## Quick Interface

The Quick Interface exposes nearly all of the features of POMDPs.jl as constructor keyword arguments. [Documentation](https://juliapomdp.github.io/QuickPOMDPs.jl/stable/quick/), Mountain Car Example:

```julia
mountaincar = QuickMDP(
    gen = function (s, a, rng)        
        x, v = s
        vp = clamp(v + a*0.001 + cos(3*x)*-0.0025, -0.07, 0.07)
        xp = x + vp
        if xp > 0.5
            r = 100.0
        else
            r = -1.0
        end
        return (sp=(xp, vp), r=r)
    end,
    actions = [-1., 0., 1.],
    initialstate = Deterministic((-0.5, 0.0)),
    discount = 0.95,
    isterminal = s -> s[1] > 0.5
)
```

Tiger POMDP Example:

```julia
tiger = QuickPOMDP(
    states = ["left", "right"],
    actions = ["left", "right", "listen"],
    observations = ["left", "right"],
    initialstate = Uniform(["left", "right"]),
    discount = 0.95,

    transition = function (s, a)
        if a == "listen"
            return Deterministic(s) # tiger stays behind the same door
        else # a door is opened
            return Uniform(["left", "right"]) # reset
        end
    end,

    observation = function (s, a, sp)
        if a == "listen"
            if sp == "left"
                return SparseCat(["left", "right"], [0.85, 0.15]) # sparse categorical distribution
            else
                return SparseCat(["right", "left"], [0.85, 0.15])
            end
        else
            return Uniform(["left", "right"])
        end
    end,

    reward = function (s, a)
        if a == "listen"
            return -1.0
        elseif s == a # the tiger was found
            return -100.0
        else # the tiger was escaped
            return 10.0
        end
    end
)
```

## Discrete Explicit Interface

The Discrete Explicit Interface is an older, less powerful interface suitable for problems with small discrete state, action, and observation spaces. Though it is less powerful, the interface may be pedagogically useful because each element of the (S, A, O, R, T, Z, γ) tuple for a POMDP and (S, A, R, T, γ) tuple for an MDP is defined explicitly in a straightforward manner. [Documentation](https://juliapomdp.github.io/QuickPOMDPs.jl/stable/discrete_explicit/), Tiger POMDP Example:

```julia
S = [:left, :right]
A = [:left, :right, :listen]
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
