struct GenerativeMDP{S, A, uuid, G} <: MDP{S, A}
    gen::G
end

function GenerativeMDP{S, A}(gen; kwargs...) where {S, A}
    uuid = uuid4()
    return GenerativeMDP{S, A, uuid, G}(gen, a_f, is_f, it_f)
end

POMDPs.generate_s(m::GenerativeMDP, s, a, rng) = m.gen(s, a, rng).sp
function POMDPs.generate_sr(m::GenerativeMDP, s, a, rng)
    x = m.gen(s, a, rng)
    return (x.sp, x.r)
end

POMDPs.actions(m::GenerativeMDP, s) = m.actions(s)
POMDPs.initialstate(m::GenerativeMDP, rng) = m.initialstate(rng)
POMDPs.initialstate(m
