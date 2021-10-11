struct QuickMDP{ID,S,A,D<:NamedTuple} <: MDP{S,A}
    data::D
end

"""
    QuickMDP(gen::Function, [id]; kwargs...)

Construct a generative MDP model with the function `gen` and keyword arguments.

`gen` should take three arguments: a state, an action, and a random number generator. It should return a `NamedTuple` with keys `sp` for the next state and `r` for the reward.

Keywords can be static objects or functions. See the QuickPOMDPs.jl documentation for more information.
"""
QuickMDP(gen::Function, id=uuid4(); kwargs...) = QuickMDP(id; gen=gen, kwargs...)

"""
    QuickMDP([id]; kwargs...)

Construct an MDP model with keyword arguments. Keywords can be static objects or functions. See the QuickPOMDPs.jl documentation for more information.
"""
function QuickMDP(id=uuid4(); kwargs...)
    kwd = Dict{Symbol, Any}(kwargs)

    for (k, v) in pairs(kwd)
        kwd[k] = preprocess(Val(k), v)
    end
    quick_defaults!(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)

    kwd = 

    d = namedtuple(keys(kwd)...)(values(kwd)...)
    qm = QuickMDP{id, S, A, typeof(d)}(d)
    return qm
end

id(::QuickMDP{ID}) where ID = ID

struct QuickPOMDP{ID,S,A,O,D<:NamedTuple} <: POMDP{S,A,O}
    data::D
end

"""
    QuickPOMDP(gen::Function, [id]; kwargs...)

Construct a generative POMDP model with the function `gen` and keyword arguments.

`gen` should take three arguments: a state, an action, and a random number generator. It should return a `NamedTuple` with keys `sp` for the next state, `o` for the observation, and `r` for the reward.

Keywords can be static objects or functions. See the QuickPOMDPs.jl documentation for more information.
"""
QuickPOMDP(gen::Function, id=uuid4(); kwargs...) = QuickPOMDP(id; gen=gen, kwargs...)

"""
    QuickPOMDP([id]; kwargs...)

Construct an POMDP model with keyword arguments. Keywords can be static objects or functions. See the QuickPOMDPs.jl documentation for more information.
"""
function QuickPOMDP(id=uuid4(); kwargs...)
    kwd = Dict{Symbol, Any}(kwargs)

    for (k, v) in pairs(kwd)
        kwd[k] = preprocess(Val(k), v)
    end
    quick_defaults!(kwd)
    quick_warnings(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)
    O = infer_obstype(kwd)
    d = namedtuple(keys(kwd)...)(values(kwd)...)
    qm = QuickPOMDP{id, S, A, O, typeof(d)}(d)
    return qm
end

id(::QuickPOMDP{ID}) where ID = ID

const QuickModel = Union{QuickMDP, QuickPOMDP}

"Function that is called on each keyword argument before anything else is done. This was designed as a hook to allow other packages to handle PyObjects."
preprocess(x) = x
preprocess(argval::Val, x) = preprocess(x)

function quick_defaults!(kwd::Dict)
    kwd[:discount] = get(kwd, :discount, 1.0)
    kwd[:isterminal] = get(kwd, :isterminal, false)
    
    if !haskey(kwd, :stateindex)
        if haskey(kwd, :states)
            states = _call(Val(:states), kwd[:states], ())
            if hasmethod(length, typeof((states,))) && length(states) < Inf
                kwd[:stateindex] = Dict(s=>i for (i,s) in enumerate(states))
            end
        end
    end

    if !haskey(kwd, :actionindex)
        if haskey(kwd, :actions)
            ka = kwd[:actions]

            # check if only a state-dependent function (e.g. s->(1,2)) is provided
            dynamic_actions_only = (ka isa Function && !hasmethod(ka, Tuple{})) || ka isa Dict

            if !dynamic_actions_only
                actions = _call(Val(:actions), ka, ())
                if hasmethod(length, typeof((actions,))) && length(actions) < Inf
                    kwd[:actionindex] = Dict(s=>i for (i,s) in enumerate(actions))
                end
            end
        end
    end

    if !haskey(kwd, :obsindex)
        if haskey(kwd, :observations)
            observations = _call(Val(:observations), kwd[:observations], ())
            if hasmethod(length, typeof((observations,))) && length(observations) < Inf
                kwd[:obsindex] = Dict(s=>i for (i,s) in enumerate(observations))
            end
        end
    end
end

function quick_warnings(kwd)
    if haskey(kwd, :initialstate)
        isd = _call(Val(:initialstate), kwd[:initialstate], ())
        try rand(MersenneTwister(0), isd)
        catch ex
            if ex isa MethodError || ex isa ArgumentError
                @warn("Unable to call rand(rng, $isd). Is the `initialstate` that you supplied a distribution?")
            else
                rethrow(ex)
            end
        end
    end

    if haskey(kwd, :reward) && !(kwd[:reward] isa Function)
        @warn("`reward` must be a function; got $(kwd[:reward])")
    end
end

function infer_statetype(kwd)
    if haskey(kwd, :statetype)
        st = _call(Val(:statetype), kwd[:statetype], (), NamedTuple())
    elseif haskey(kwd, :states)
        st = eltype(_call(Val(:states), kwd[:states], (), NamedTuple()))
    elseif haskey(kwd, :initialstate)
        st = typeof(rand(MersenneTwister(0), _call(Val(:initialstate), kwd[:initialstate], (), NamedTuple())))
    else
        st = Any
    end
    if st == Any
        @warn("Unable to infer state type for a Quick(PO)MDP; using Any. This may have significant performance consequences. Use the statetype keyword argument to specify a concrete state type.")
    end
    return st
end

function infer_actiontype(kwd)
    if haskey(kwd, :actiontype)
        at = _call(Val(:actiontype), kwd[:actiontype], (), NamedTuple())
    elseif haskey(kwd, :actions)
        kwa = kwd[:actions]
        if kwa isa Function && !hasmethod(kwd[:actions], Tuple{})
            at = Any
        elseif kwa isa Dict
            at = valtype(kwa)
        else
            at = eltype(_call(Val(:actions), kwd[:actions], (), NamedTuple()))
        end
    else
        at = Any
    end
    if at == Any
        @warn("Unable to infer action type for a Quick(PO)MDP; using Any. This may have significant performance consequences. Use the actiontype keyword argument to specify a concrete action type.")
    end
    return at
end

function infer_obstype(kwd)
    if haskey(kwd, :obstype)
        ot = _call(Val(:obstype), kwd[:obstype], (), NamedTuple())
    elseif haskey(kwd, :observations)
        ot = eltype(_call(Val(:observations), kwd[:observations], (), NamedTuple()))
    elseif haskey(kwd, :initialobs) && haskey(kwd, :initialstate)
        s0 = rand(MersenneTwister(0), _call(Val(:initialstate), kwd[:initialstate], (), NamedTuple()))
        ot = typeof(rand(MersenneTwister(0), _call(Val(:initialobs), kwd[:initialobs], (s0,), NamedTuple())))
    else
        ot = Any
    end
    if ot == Any
        @warn("Unable to infer observation type for a QuickPOMDP; using Any. This may have significant performance consequences. Use the obstype keyword argument to specify a concrete observation type.")
    end
    return ot
end


function _call(namev::Val{name}, m::QuickModel, args, kwargs=NamedTuple()) where name
    _call(namev,
          get(m.data, name) do
              throw(MissingQuickArgument(m, name))
          end,
          args,
          kwargs)
end

_call(::Val, f::Function, args, kwargs=NamedTuple()) = f(args...; kwargs...)
_call(v::Val, object, args, kwargs=NamedTuple()) = object
_call(v::Val, d::Dict, args, kwargs=NamedTuple()) = d[args...]

macro forward_to_data(f)
    @assert f.head == :. "@forward_to_data must be used with a module-qualified function expression, e.g. @forward_to_data POMDPs.discount"
    quote
        $f(m::QuickModel, args...; kwargs...) = _call(Val($(f.args[2])), m, args, kwargs)
    end
end

function POMDPs.transition(m::QuickModel, s, a)
    if haskey(m.data, :transition)
        return m.data.transition(s, a)
    else
        throw(MissingQuickArgument(m, :transition, types=[Function], also=[:gen]))
    end
end

function POMDPs.observation(m::QuickPOMDP, args...)
    if haskey(m.data, :observation)
        obs = m.data[:observation]
        if hasmethod(obs, typeof(args))
            return obs(args...)
        elseif length(args) == 3 && hasmethod(obs, typeof(args[2:3]))
            return obs(args[2:3]...)
        else
            return obs(args...)
        end
        return m.data.observation(args...)
    else
        throw(MissingQuickArgument(m, :observation, types=[Function], also=[:gen]))
    end
end

function POMDPs.reward(m::QuickModel, args...)
    if haskey(m.data, :reward)
        r = m.data[:reward]
        if hasmethod(r, typeof(args)) # static_hasmethod could cause issues, but I think it is worth doing in this single spot
            return r(args...)
        elseif m isa POMDP && length(args) == 4
            if hasmethod(r, typeof(args[1:3])) # (s, a, sp, o) -> (s, a, sp)
                return r(args[1:3]...)
            elseif hasmethod(r, typeof(args[1:2])) # (s, a, sp, o) -> (s, a)
                return r(args[1:2]...)
            end
        elseif length(args) == 3 && hasmethod(r, typeof(args[1:2])) # (s, a, sp) -> (s, a)
            return r(args[1:2]...)
        else
            return r(args...)
        end
    else
        throw(MissingQuickArgument(m, :reward))
    end
end

struct QuickRewardModel{ArgNums, F} <: Function
    f::F
    hasmethod_fallback::Bool
end

QuickRewardModel(f::Function, S, A; hasmethod_fallback::Bool=true) = QuickRewardModel{reward_argnums(f, S, A), typeof(f)}(f, hasmethod_fallback)
QuickRewardModel(f::Function, S, A, O; hasmethod_fallback::Bool=true) = QuickRewardModel{reward_argnums(f, S, A, O), typeof(f)}(f, hasmethod_fallback)
QuickRewardModel(r::QuickRewardModel, args...) = r

function reward_argnums(f, S, A)
    ans = []
    if hasmethod(f, Tuple{S,A})
        push!(ans, 2)
    end
    if hasmethod(f, Tuple{S,A,S})
        push!(ans, 3)
    end
    return (ans...,) # convert to tuple
end

function reward_argnums(f, S, A, O)
    if hasmethod(f, Tuple{S, A, S, O})
        return (reward_argnums(f, S, A)..., 4)
    else
        return reward_argnums(f, S, A)
    end
end

function (r::QuickRewardModel{ArgNums})(args...) where ArgNums
    if length(args) in ArgNums
        return r.f(args...)
    elseif maximum(ArgNums) < length(args)
        return r.f(args[1:maximum(ArgNums)]...)
    elseif r.f.hasmethod_fallback
        if hasmethod(r.f, typeof(args))
            found = r.f(args...)
        elseif m isa POMDP && length(args) == 4
            if hasmethod(r.f, typeof(args[1:3])) # (s, a, sp, o) -> (s, a, sp)
                found = r.f(args[1:3]...)
            elseif hasmethod(r.f, typeof(args[1:2])) # (s, a, sp, o) -> (s, a)
                found = r.f(args[1:2]...)
            end
        elseif length(args) == 3 && hasmethod(r.f, typeof(args[1:2])) # (s, a, sp) -> (s, a)
            found = r.f(args[1:2]...)
        else
            return r.f(args...)
        end
        @warn("""A Quick(PO)MDP had to use hasmethod as a fallback to find the correct method of
                 the reward function to use.

                 This may be caused by adding new methods to the reward function after creating
                 the Quick(PO)MDP and can cause significant perfromance degredation. Originally,
                 the Quick(PO)MDP found reward methods with the following numbers of arguments:

                 $(ArgNums)

                 Recommend adding all methods to the reward function before creaing the
                 Quick(PO)MDP.""", current_methods=methods(r.f))
        return found
    else
        return r.f(args...)
    end
end

@forward_to_data POMDPs.initialstate
@forward_to_data POMDPs.initialobs

function POMDPs.gen(m::QuickModel, s, a, rng)
    if haskey(m.data, :gen)
        return m.data.gen(s, a, rng)
    else
        return NamedTuple()
    end
end

@forward_to_data POMDPs.states
@forward_to_data POMDPs.actions
@forward_to_data POMDPs.observations
@forward_to_data POMDPs.discount

@forward_to_data POMDPs.stateindex
@forward_to_data POMDPs.actionindex
@forward_to_data POMDPs.obsindex
@forward_to_data POMDPs.isterminal


function POMDPModelTools.obs_weight(m::QuickPOMDP, args...)
    if haskey(m.data, :obs_weight)
        return _call(Val(:obs_weight), m, args)
    elseif haskey(m.data, :observation)
        return pdf(observation(m, args[1:end-1]...), args[end])
    else
        throw(MissingQuickArgument(m, :obs_weight, types=[Function], also=[:observation]))
    end
end
@forward_to_data POMDPModelTools.render

function POMDPModelTools.StateActionReward(m::Union{QuickPOMDP,QuickMDP})
    if hasmethod(m.data[:reward], Tuple{statetype(m), actiontype(m)})
        return FunctionSAR(m)
    else
        return LazyCachedSAR(m)
    end
end
