struct DiscreteExplicitPOMDP{S,A,O,OF,RF,D} <: POMDP{S,A,O}
    s::Vector{S}
    a::Vector{A}
    o::Vector{O}
    tds::Dict{Tuple{S,A}, SparseCat{Vector{S}, Vector{Float64}}}
    ods::Dict{Tuple{A,S}, SparseCat{Vector{O}, Vector{Float64}}}
    ofun::OF
    r::RF
    smap::Dict{S,Int}
    amap::Dict{A,Int}
    omap::Dict{O,Int}
    discount::Float64
    initial::D
    terminals::Set{S}
end

struct DiscreteExplicitMDP{S,A,RF,D} <: MDP{S,A}
    s::Vector{S}
    a::Vector{A}
    tds::Dict{Tuple{S,A}, SparseCat{Vector{S}, Vector{Float64}}}
    r::RF
    smap::Dict{S,Int}
    amap::Dict{A,Int}
    discount::Float64
    initial::D
    terminals::Set{S}
end

const DEP{S,A,O} = DiscreteExplicitPOMDP
const DE{S,A} = Union{DiscreteExplicitPOMDP{S,A},DiscreteExplicitMDP{S,A}}

POMDPs.discount(m::DE) = m.discount
POMDPs.states(m::DE) = m.s
POMDPs.actions(m::DE) = m.a
POMDPs.n_states(m::DE) = length(m.s)
POMDPs.n_actions(m::DE) = length(m.a)
POMDPs.stateindex(m::DE, s) = m.smap[s]
POMDPs.actionindex(m::DE, a) = m.amap[a]

POMDPs.observations(m::DEP) = m.o
POMDPs.n_observations(m::DEP) = length(m.o)
POMDPs.obsindex(m::DEP, o) = m.omap[o]
POMDPModelTools.obs_weight(m::DEP, a, sp, o) = m.ofun(a, sp, o)

POMDPs.transition(m::DE, s, a) = m.tds[s,a]
POMDPs.observation(m::DEP, a, sp) = m.ods[a,sp]
POMDPs.reward(m::DE, s, a) = m.r(s, a)

POMDPs.initialstate_distribution(m::DE) = m.initial

POMDPs.isterminal(m::DE,s) = s in m.terminals

POMDPModelTools.ordered_states(m::DE) = m.s
POMDPModelTools.ordered_actions(m::DE) = m.a
POMDPModelTools.ordered_observations(m::DEP) = m.o


"""
    DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ,[b₀],[terminal=Set()])

Create a POMDP defined by the tuple (S,A,O,T,Z,R,γ).

# Arguments

## Required
- `S`,`A`,`O`: State, action, and observation spaces (typically `Vector`s)
- `T::Function`: Transition probability distribution function; ``T(s,a,s')`` is the probability of transitioning to state ``s'`` from state ``s`` after taking action ``a``.
- `Z::Function`: Observation probability distribution function; ``O(a, s', o)`` is the probability of receiving observation ``o`` when state ``s'`` is reached after action ``a``.
- `R::Function`: Reward function; ``R(s,a)`` is the reward for taking action ``a`` in state ``s``.
- `γ::Float64`: Discount factor.

## Optional
- `b₀=Uniform(S)`: Initial belief/state distribution (See `POMDPModelTools.Deterministic` and `POMDPModelTools.SparseCat` for other options).

## Keyword
- `terminals=Set()`: Set of terminal states. Once a terminal state is reached, no more actions can be taken or reward received.
"""
function DiscreteExplicitPOMDP(s, a, o, t, z, r, discount, b0=Uniform(s); terminals=Set())
    ss = vec(collect(s))
    as = vec(collect(a))
    os = vec(collect(o))
    ST = eltype(ss)
    AT = eltype(as)
    OT = eltype(os)

    tds = filltds(t, ss, as)

    # TODO parallelize?
    ods = Dict{Tuple{AT, ST}, SparseCat{Vector{OT}, Vector{Float64}}}()
    for u in as
        for xp in ss
            ys = OT[]
            ps = Float64[]
            for y in os
                p = z(u, xp, y)
                if p > 0.0
                    push!(ys, y)
                    push!(ps, p)
                end
            end
            ods[u,xp] = SparseCat(ys, ps)
        end
    end

    m = DiscreteExplicitPOMDP(
        ss, as, os,
        tds, ods,
        z, r,
        Dict(ss[i]=>i for i in 1:length(ss)),
        Dict(as[i]=>i for i in 1:length(as)),
        Dict(os[i]=>i for i in 1:length(os)),
        discount, b0, convert(Set{eltype(ss)}, terminals)
    )

    probability_check(m)

    return m
end

"""
    DiscreteExplicitMDP(S,A,T,R,γ,[p₀])

Create an MDP defined by the tuple (S,A,T,R,γ).

# Arguments

## Required
- `S`,`A`: State and action spaces (typically `Vector`s)
- `T::Function`: Transition probability distribution function; ``T(s,a,s')`` is the probability of transitioning to state ``s'`` from state ``s`` after taking action ``a``.
- `R::Function`: Reward function; ``R(s,a)`` is the reward for taking action ``a`` in state ``s``.
- `γ::Float64`: Discount factor.

## Optional
- `p₀=Uniform(S)`: Initial state distribution (See `POMDPModelTools.Deterministic` and `POMDPModelTools.SparseCat` for other options).

## Keyword
- `terminals=Set()`: Set of terminal states. Once a terminal state is reached, no more actions can be taken or reward received.
"""
function DiscreteExplicitMDP(s, a, t, r, discount, p0=Uniform(s); terminals=Set())
    ss = vec(collect(s))
    as = vec(collect(a))

    tds = filltds(t, ss, as)

    m = DiscreteExplicitMDP(
        ss, as, tds, r,
        Dict(ss[i]=>i for i in 1:length(ss)),
        Dict(as[i]=>i for i in 1:length(as)),
        discount, p0, convert(Set{eltype(ss)}, terminals)
    )

    trans_prob_consistency_check(m)

    return m
end

function filltds(t, ss, as)
    ST = eltype(ss)
    AT = eltype(as)
    tds = Dict{Tuple{ST, AT}, SparseCat{Vector{ST}, Vector{Float64}}}()
    # TODO parallelize?
    for x in ss
        for u in as
            xps = ST[]
            ps = Float64[]
            for xp in ss
                p = t(x, u, xp)
                if p > 0.0
                    push!(xps, xp)
                    push!(ps, p)
                end
            end
            tds[x,u] = SparseCat(xps, ps)
        end
    end
    return tds
end

POMDPs.convert_s(::Type{V}, s, m::DE) where V<:AbstractVector = convert_to_vec(V, s, m.smap)
POMDPs.convert_a(::Type{V}, a, m::DE) where V<:AbstractVector = convert_to_vec(V, a, m.amap)
POMDPs.convert_o(::Type{V}, o, m::DEP) where V<:AbstractVector = convert_to_vec(V, o, m.omap)

POMDPs.convert_s(::Type{S}, v::AbstractArray{N}, m::DE{S}) where {S,N<:Number} = convert_from_vec(S, v, m.s)
POMDPs.convert_a(::Type{A}, v::AbstractArray{N}, m::DE{<:Any,A}) where {A,N<:Number} = convert_from_vec(A, v, m.a)
POMDPs.convert_o(::Type{O}, v::AbstractArray{N}, m::DEP{<:Any,<:Any,O}) where {O,N<:Number} = convert_from_vec(O, v, m.o)

# if states are numbers, try to preserve
POMDPs.convert_s(::Type{V}, s::Number, m::DE) where V<:AbstractVector{N} where N<:Number = convert(V, [s])
POMDPs.convert_a(::Type{V}, a::Number, m::DE) where V<:AbstractVector{N} where N<:Number = convert(V, [a])
POMDPs.convert_o(::Type{V}, o::Number, m::DEP) where V<:AbstractVector{N} where N<:Number = convert(V, [o])

POMDPs.convert_s(::Type{N}, v::AbstractVector{F}, m::DE) where {N<:Number, F<:Number} = convert(N, first(v))
POMDPs.convert_a(::Type{N}, v::AbstractVector{F}, m::DE) where {N<:Number, F<:Number} = convert(N, first(v))
POMDPs.convert_o(::Type{N}, v::AbstractVector{F}, m::DEP) where {N<:Number, F<:Number} = convert(N, first(v))

# if states are vectors, try to preserve
POMDPs.convert_s(T::Type{A1}, s::A2, m::DE) where {A1<:AbstractVector, A2<:AbstractVector} = convert(T, s)
POMDPs.convert_a(T::Type{A1}, a::A2, m::DE) where {A1<:AbstractVector, A2<:AbstractVector} = convert(T, a)
POMDPs.convert_o(T::Type{A1}, o::A2, m::DEP) where {A1<:AbstractVector, A2<:AbstractVector} = convert(T, o)

# for things that aren't numbers
convert_to_vec(V, x, map) = convert(V, [map[x]])
convert_from_vec(T, v, space) = convert(T, space[convert(Integer, first(v))])
