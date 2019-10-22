struct QuickMDP{ID,S,A,D<:NamedTuple} <: MDP{S,A}
    data::D
end

QuickMDP(gen::Function, id=uuid4(); kwargs...) = QuickMDP(id; gen=gen, kwargs...)

function QuickMDP(id=uuid4(); kwargs...)
    kwd = Dict{Symbol, Any}(kwargs)

    quick_defaults!(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)
    d = namedtuple(keys(kwd)...)(values(kwd)...)
    qm = QuickMDP{id, S, A, typeof(d)}(d)
    return qm
end

struct QuickPOMDP{ID,S,A,O,D<:NamedTuple} <: POMDP{S,A,O}
    data::D
end

QuickPOMDP(gen::Function, id=uuid4(); kwargs...) = QuickMDP(id; gen=gen, kwargs...)

function QuickPOMDP(id=uuid4(); kwargs...)
    kwd = Dict{Symbol, Any}(kwargs)

    quick_defaults!(kwd)

    S = infer_statetype(kwd)
    A = infer_actiontype(kwd)
    d = namedtuple(keys(kwd)...)(values(kwd)...)
    qm = QuickMDP{id, S, A, typeof(d)}(d)
    lint(qm)
    return qm
end

const QuickModel = QuickMDP

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
        st = _call(Val(:actiontype), kwd[:actiontype], (), NamedTuple())
    elseif haskey(kwd, :actions)
        st = eltype(_call(Val(:actions), kwd[:actions], (), NamedTuple()))
    else
        st = Any
    end
    if st == Any
        @warn("Unable to infer action type for a Quick(PO)MDP; using Any. This may have significant performance consequences. Use the actiontype keyword argument to specify a concrete action type.")
    end
    return st
end

function _call(namev::Val{name}, m::QuickMDP, args, kwargs=NamedTuple()) where name
    _call(namev,
          get(m.data, name) do
              throw(MissingQuickArg(m, name))
          end,
          args,
          kwargs)
end

_call(::Val, f::Function, args, kwargs) = f(args...; kwargs...)
_call(v::Val, object, args, kwargs) = object
_call(v::Val, d::Dict, args, kwargs) = d[args]

macro forward_to_data(f)
    quote
        $f(m::QuickMDP, args...; kwargs...) = _call(Val(nameof($f)), m, args, kwargs)
    end
end

function POMDPs.transition(m::QuickModel, s, a)
    if haskey(m.data, :transition)
        return m.data.transition(s, a)
    else
        throw(MissingQuickArg(m, :transition, types=[Function], also=[:gen]))
    end
end

function POMDPs.observation(m::QuickPOMDP, args...)
    if haskey(m.data, :observation)
        return m.data.observation(args...)
    else
        throw(MissingQuickArg(m, :observation, types=[Function], also=[:gen]))
    end
end

@forward_to_data POMDPs.initialstate_distribution
@forward_to_data POMDPs.reward

@forward_to_data POMDPs.gen # Note DDNNode and DDNOut methods explicitly not forwarded
@forward_to_data POMDPs.initialstate

# function POMDPs.initialstate(m::QuickModel, rng)
#     if haskey(m.data, :initialstate)
#         return _call(Val(:initialstate), m, (rng,))
#     elseif haskey(m.data, :initialstate_distribution)
#         return rand(rng, _call(Val(:initialstate_distribution), m))
#     else
#         throw(MissingQuickArg(m, :initialstate, types=[statetype(m), Function], also=[:initialstate_distribution]))
#     end
# end

function POMDPs.initialobs(m::QuickPOMDP, s, rng)
    if haskey(m.data, :initialobs)
        return _call(Val(:initialobs), m, (s, rng))
    elseif haskey(m.data, :observation) && hasmethod(m.data.observation, typeof((s,)))
        return rand(rng, m.data.observation(s))
    else
        throw(MissingQuickArg(m, :initialobs, types=[obstype(m), Function], also=[:observation]))
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
