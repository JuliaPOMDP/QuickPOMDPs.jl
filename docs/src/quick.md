# Quick Interface

The Quick Interface is designed for defining simple POMDPs in a few lines without any object oriented programming. It exposes nearly all of the problem definition features of POMDPs.jl through constructor keyword arguments.

## Example

The quick interface is perhaps best demonstrated by an example. The code below defines the classic "Mountain Car" problem from 
[OpenAI Gym](https://github.com/openai/gym/blob/master/gym/envs/classic_control/mountain_car.py).

```jldoctest; output = false, filter = r".*"
using QuickPOMDPs

mountaincar = QuickMDP(
    function (s, a, rng)        
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
    initialstate = (-0.5, 0.0),
    discount = 0.95,
    isterminal = s -> s[1] > 0.5
)

# output

```

Here, the first argument to the `QuickMDP` constructor is a function that defines the generative model of the MDP. It returns a `NamedTuple` containing the next state and reward given the current state and action.

!!! note

    Quick(PO)MDPs need not be generative models. Explicit Quick(PO)MDPs can be defined by leaving out the generative function positional argument and providing the `transition`, `observation`, and `reward` keyword arguments. An example of this style can be found in [examples/lightdark.jl](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/lightdark.jl).

The other keyword arguments define the remaining elements of the problem such as the action space, discount factor and when to terminate.

## Keyword arguments

The keyword arguments correspond to functions in the [POMDPs.jl interface](https://juliapomdp.github.io/POMDPs.jl/stable/api/#Index-1). More information for each can be found in the [docstring for the function](https://juliapomdp.github.io/POMDPs.jl/stable/api/#Model-Functions-1).

The currently supported keyword arguments are
```
transition
observation
initialstate_distribution
reward
initialstate
initialobs
states
actions
observations
discount
stateindex
actionindex
obsindex
isterminal
obs_weight (from POMDPModelTools)
render (from POMDPModelTools)
```

!!! note

    The `gen` function (which should always return a `NamedTuple`) can be defined as a first positional argument (or with the `do` syntax) or using the `gen` keyword.

### Keyword arguments may be functions or objects

Most keyword arguments may be either functions or static objects. For instance, in the above example, the action space is specified by a static list provided as the `actions` keyword argument. In other problems, the action space might be state-dependent and hence specified as a function of the state, for instance if the mountain car only had a braking action, the following code might be used:
```julia
actions = function (s)
    v = s[2]
    if v >= 0.0
        return [0., -1.]
    else
        return [0., 1.]
    end
end
```

When the keyword argument is a function, it should take all of the arguments that the corresponding POMDPs.jl function takes, but *without the model argument*. For instance, the signature for `POMDPs.isterminal` is `isterminal(m::Union{POMDP, MDP}, s)`, so the `isterminal` keyword argument takes a function of only `s` (the `m` model argument is omitted) as shown in the example above.

!!! note

    When the POMDPs.jl function has a variable number of arguments, it can be confusing to know which version to implement. For example POMDPs.jl has the methods
    ```julia
    reward(m, s, a)
    reward(m, s, a, sp)
    reward(m, s, a, sp, o)
    ```
    in the interface. Usually the best bet is to implement the one with the most arguments, i.e.
    ```julia
    reward = (s, a, sp, o) -> s^2
    ```
    However, in general, a specific solver may require a specific number of arguments (keep an eye out for `MethodErrors` to know which version is needed). If multiple methods are needed, they can be defined outside of the Quick(PO)MDP constructor, e.g.
    ```julia
    myreward(s, a) = s^2
    myreward(s, a, sp) = s^2
    m = QuickMDP(
        ...
        reward = myreward,
        ...
    )
    ```

## IDs and defining methods

Each Quick(PO)MDP has a unique id, which is stored as a type parameter. By default this id is randomly generated, but it can also be specified as a positional argument.

This ID type parameter allows specialized methods to be defined for a specific Quick(PO)MDP. For example one could override `ordered_states` function from `POMDPModelTools` as follows:

```julia
m = QuickMDP(...)

POMDPModelTools.ordered_states(m::typeof(m)) = 1:3
```
or
```julia
m = QuickMDP(:myproblem, ...)

POMDPModelTools.ordered_states(m::QuickMDP{:myproblem}) = 1:3
```

!!! note
    
    A manually-specified ID must be a suitable type parameter value such as a `Symbol` or other `isbits` type.

## State, action, and observation type inference

The state, action, and observation types for a Quick(PO)MDP are usually inferred from the keyword arguments. For instance, in the example above, the state type is inferred to be `Tuple{Float64, Float64}` from the `initialstate` argument, and the action type is inferred to be `Float64` from the `actions` argument. If QuickPOMDPs is unable to infer one of these types, or the user wants to override or specify the type manually, the `statetype`, `actiontype`, or `obstype` keywords should be used.

## Visualization

Visualization can be accomplished using the `render` keyword argument. See the [documentation of `POMDPModelTools.render`](https://juliapomdp.github.io/POMDPModelTools.jl/latest/visualization.html#POMDPModelTools.render) for more information. An example can be found in [example/mountaincar_with_visualization.jl](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/lightdark.jl).
