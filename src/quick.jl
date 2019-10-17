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
    return QuickMDP{id, S, A, typeof(d)}(d)
end

struct QuickPOMDP{ID,S,A,O,D<:NamedTuple} <: POMDP{S,A,O}

function infer_statetype(kwd)
    if haskey(kwd, :statetype)
        st = _call(Val(:statetype), kwd[:statetype], (), NamedTuple())
    elseif haskey(kwd, :states)
        st = eltype(_call(Val(:states), kwd[:states], (), NamedTuple()))
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
              error("No key $name in m.data") # TODO improve error message
          end,
          args,
          kwargs)
end

_call(::Val, f::Function, args, kwargs) = f(args...; kwargs...)
_call(v::Val, object, args, kwargs) = begin @show v; object end

macro forward_to_data(f)
    quote
        $f(m::QuickMDP, args...) = _call(Val(nameof($f)), m, args)
    end
end

@forward_to_data POMDPs.transition
@forward_to_data POMDPs.observation
@forward_to_data POMDPs.initialstate_distribution
@forward_to_data POMDPs.reward

@forward_to_data POMDPs.gen # Note DDNNode and DDNOut methods explicitly not forwarded
@forward_to_data POMDPs.initialstate
@forward_to_data POMDPs.initialobs

@forward_to_data POMDPs.states
@forward_to_data POMDPs.actions
@forward_to_data POMDPs.observations
@forward_to_data POMDPs.discount

POMDPs.stateindex
POMDPs.actionindex
POMDPs.obsindex

POMDPs.isterminal
