# QuickPOMDPs

Eventually this will be a repository containing more simplified interfaces for expressing certain classes of POMDPs. The goal is for [POMDPs.jl]( https://github.com/JuliaPOMDP/POMDPs.jl) to act as a low level interface (like [MathProgBase](https://github.com/JuliaOpt/MathProgBase.jl)) and for the interface(s) defined here to act as concise and convenient high-level interface (like [JuMP](https://github.com/JuliaOpt/JuMP.jl) or [Convex](https://github.com/JuliaOpt/Convex.jl)).

Another package that should be referenced when designing this is [PLite.jl](https://github.com/sisl/PLite.jl/blob/master/docs/README.md).

Contributions of new interfaces for defining specific classes of problems are welcome!

For now, there are just a few sketches of interfaces outlined below:

# Interface Ideas

## Basic Discrete

Can represent any problem with discrete actions, observations, and states using the POMDPs.jl explicit interface. This would just be a tight wrapper over the POMDPs.jl interface and would look very similar to a pure POMDPs.jl implementation. Advantages over direct POMDPs.jl are that it's slightly more compact and **you don't have to understand object-oriented programming**.

The Tiger problem would look like this:

```julia
pomdp = @discretePOMDP begin
    @states [:tiger_l, :tiger_r]
    @actions [:open_l, :open_r, :listen]
    @observations [:tiger_l, :tiger_r]

    @transition function (s, a)
        if a == :listen
            return [s]=>[1.0]
        else 
            return [TIGER_L, TIGER_R]=>[0.5, 0.5] # reset
        end
    end

    @reward Dict((:tiger_l, :open_l) => -100.,
                  (:tiger_r, :open_r) => -100.,
                  (:tiger_l, :open_r) => 10.,
                  (:tiger_r, :open_l) => 10.
                 )

    @default_reward -1.0

    @observation function (a, sp)
        if a == :listen
            if sp == :tiger_l
                return [:tiger_l, :tiger_r]=>[0.85, 0.15]
            else
                return [:tiger_r, :tiger_l]=>[0.85, 0.15]
            end
        else
            return [:tiger_l, :tiger_r]=>[0.5, 0.5]
        end
    end

    @initial [:tiger_l, :tiger_r]=>[0.5, 0.5]
    @discount 0.95
end
```

Note, this could also be done without any macros as a constructor with keyword arguments. Perhaps that would be easier to understand?

## Generative Function

Another common problem is one where the dynamics are given by a function. The crying baby problem would look something like this:

```julia
pomdp = @generativePOMDP begin
    @initial rng -> rand(rng) > 0.5

    @dynamics function (s, a, rng)
        if s # hungry
            sp = true
        else # not hungry
            sp = rand(rng) < 0.1 ? true : false
        end
        if sp # hungry
            o = rand(rng) < 0.8 ? true : false
        else # not hungry
            o = rand(rng) < 0.1 ? true : false
        end
        r = (s ? -10.0 : 0.0) + (a ? -5.0 : 0.0)
        return s, o, r
    end

    @discount 0.95
end
```

Again, you could do this without macros, and just use keyword arguments.

## Named Variables

It might also be more clear what is going on if we declared variables with names as shown in the example below.

This would be tougher to compile though, and it's not clear what the easiest way to express distributions or reward would be.

Ideas welcome!

```julia
mdp = @MDP begin
    xmax = 10
    ymax = 10

    @states begin
        x in 1:10
        y in 1:10
    end

    @actions begin
        dir in [:up, :down, :left, :right]
    end

    @reward rdict = Dict(
                    #XXX no idea how to define this in terms of x and y
                 )
    default_reward = 0.0

    @transition #XXX what is the most concise way to define the transition distribution??

    terminal = vals(reward)
    discount = 0.95

    initial
end
```
