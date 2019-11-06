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

    quick_defaults!(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)
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

    quick_defaults!(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)
    O = infer_obstype(kwd)
    d = namedtuple(keys(kwd)...)(values(kwd)...)
    qm = QuickPOMDP{id, S, A, O, typeof(d)}(d)
    return qm
end

id(::QuickPOMDP{ID}) where ID = ID

const QuickModel = Union{QuickMDP, QuickPOMDP}

function quick_defaults!(kwd::Dict)
    kwd[:discount] = get(kwd, :discount, 1.0)
    kwd[:isterminal] = get(kwd, :isterminal, false)
    
    # memoize initialstate_distribution since it should be constant (so we can use it below for initialstate)
    if haskey(kwd, :initialstate_distribution) && kwd[:initialstate_distribution] isa Function
        kwd[:initialstate_distribution] = kwd[:initialstate_distribution]()
    end
   
    if !haskey(kwd, :initialstate)
        if haskey(kwd, :initialstate_distribution)
            kwd[:initialstate] = rng -> rand(rng, kwd[:initialstate_distribution])
        end                                      
    end

    # default for initialobs must be in the method below because the method table might change

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
            actions = _call(Val(:actions), kwd[:actions], ())
            if hasmethod(length, typeof((actions,))) && length(actions) < Inf
                kwd[:actionindex] = Dict(s=>i for (i,s) in enumerate(actions))
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

function infer_statetype(kwd)
    if haskey(kwd, :statetype)
        st = _call(Val(:statetype), kwd[:statetype], (), NamedTuple())
    elseif haskey(kwd, :states)
        st = eltype(_call(Val(:states), kwd[:states], (), NamedTuple()))
    elseif haskey(kwd, :initialstate)
        st = typeof(_call(Val(:initialstate), kwd[:initialstate], (MersenneTwister(0),), NamedTuple()))
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
        at = eltype(_call(Val(:actions), kwd[:actions], (), NamedTuple()))
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
        s0 = _call(Val(:initialstate), kwd[:initialstate], (MersenneTwister(0),), NamedTuple())
        ot = typeof(_call(Val(:initialobs), kwd[:initialobs], (s0, MersenneTwister(0),), NamedTuple()))
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
_call(v::Val, d::Dict, args, kwargs=NamedTuple()) = d[args]

macro forward_to_data(f)
    quote
        $f(m::QuickModel, args...; kwargs...) = _call(Val(nameof($f)), m, args, kwargs)
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
        return m.data.observation(args...)
    else
        throw(MissingQuickArgument(m, :observation, types=[Function], also=[:gen]))
    end
end

@forward_to_data POMDPs.initialstate_distribution
@forward_to_data POMDPs.reward

function POMDPs.gen(m::QuickModel, s, a, rng)
    if haskey(m.data, :gen)
        return m.data.gen(s, a, rng)
    else
        return NamedTuple()
    end
end

POMDPs.initialstate(m::QuickModel, rng::AbstractRNG) = _call(Val(:initialstate), m, (rng,))

function POMDPs.initialobs(m::QuickPOMDP, s, rng::AbstractRNG)
    if haskey(m.data, :initialobs)
        return _call(Val(:initialobs), m, (s, rng))
    elseif haskey(m.data, :observation) && hasmethod(m.data.observation, typeof((s,)))
        return rand(rng, m.data.observation(s))
    else
        throw(MissingQuickArgument(m, :initialobs, types=[obstype(m), Function], also=[:observation]))
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

@forward_to_data POMDPModelTools.obs_weight
@forward_to_data POMDPModelTools.render
