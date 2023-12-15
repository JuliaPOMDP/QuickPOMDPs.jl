@testset "Quick" begin
    qm = QuickMDP(statetype=Int, actiontype=Int)
    @test @inferred(statetype(qm)) == Int
    @test @inferred(actiontype(qm)) == Int
    @test @inferred(discount(qm)) == 1.0
    @test @inferred(isterminal(qm, 1)) == false
    @test_throws MissingQuickArgument transition(qm, 1, 1)
    @test_throws MissingQuickArgument initialstate(qm)
    @test_throws MissingQuickArgument reward(qm, 1, 1, 1)
    @test_throws MissingQuickArgument initialstate(qm)
    @test_throws MissingQuickArgument states(qm)
    @test_throws MissingQuickArgument actions(qm)
    @test_throws MissingQuickArgument stateindex(qm, 1)
    @test_throws MissingQuickArgument actionindex(qm, 1)
 
    qp = QuickPOMDP(obstype=Int)
    @test @inferred(obstype(qp)) == Int
    @test @inferred(statetype(qp)) == Any
    @test @inferred(actiontype(qp)) == Any
    @test @inferred(discount(qp)) == 1.0
    @test @inferred(isterminal(qp, 1)) == false
    @test_throws MissingQuickArgument transition(qp, 1, 1)
    @test_throws MissingQuickArgument observation(qp, 1, 1)
    @test_throws MissingQuickArgument initialstate(qp)
    @test_throws MissingQuickArgument reward(qp, 1, 1, 1)
    @test_throws MissingQuickArgument initialstate(qp)
    @test_throws MissingQuickArgument initialobs(qp, 1)
    @test_throws MissingQuickArgument states(qp)
    @test_throws MissingQuickArgument actions(qp)
    @test_throws MissingQuickArgument observations(qp)
    @test_throws MissingQuickArgument stateindex(qp, 1)
    @test_throws MissingQuickArgument actionindex(qp, 1)
    @test_throws MissingQuickArgument obsindex(qp, 1)
    
    @test_throws MissingQuickArgument @gen(:sp,:o,:r)(qp, 1, 1, MersenneTwister(2))

    qp = QuickMDP(states=[3,2,1], actions=[1,2,3])
    @test ordered_states(qp) == [3,2,1]
    @test ordered_actions(qp) == [1,2,3]
end

@testset "Mountan Car" begin
    mountaincar = begin
        include("../examples/mountaincar.jl")
    end

    @show statetype(mountaincar)

    energize = FunctionPolicy(
        function (s)
            if s[2] < 0.0
                return minimum(actions(mountaincar))
            else
                return maximum(actions(mountaincar))
            end
        end
    ) 
    sim = HistoryRecorder(max_steps=1000)
    # below should work with a new version of POMDPSimulators
    @test_skip simulate(sim, mountaincar, energize) != nothing
    hist = simulate(sim, mountaincar, energize, rand(initialstate(mountaincar)))
    @test maximum(hist[:r]) == 100.0
    @test all(isa.(hist[:s], statetype(mountaincar)))
    @test last(collect(hist[:sp]))[1] > 0.5
end

@testset "Mountan Car Visualization" begin
    m = begin
        include("../examples/mountaincar_with_visualization.jl")
    end
    
    @inferred @gen(:sp,:r)(m, (0.2, 0.0), 0.0, MersenneTwister(2))

    energize = FunctionPolicy(
        function (s)
            if s[2] < 0.0
                return minimum(actions(m))
            else
                return maximum(actions(m))
            end
        end
    ) 
    sim = HistoryRecorder(max_steps=1000)
    # below should work when POMDPSimulators is fixed, but it can be deleted then
    @test_skip simulate(sim, m, energize) != nothing
    hist = simulate(sim, m, energize, rand(initialstate(m)))
    @test maximum(hist[:r]) == 100.0
    @test all(isa.(hist[:s], statetype(mountaincar)))
    @test last(collect(hist[:sp]))[1] > 0.5
    draw(SVG("test_render.svg", 5cm, 4cm), render(m, (s=(0.2, 0.0),)))
    @test isfile("test_render.svg")
end

@testset "Simple Light-Dark" begin
    m = begin
        include("../examples/lightdark.jl")
    end
    p = RandomPolicy(m, rng = MersenneTwister(2))
    sim = HistoryRecorder(max_steps=1000)
    up = DiscreteUpdater(m)
    hist = simulate(sim, m, p, up)
    @test all(-100 .<= hist[:r] .<= 100)
    @test all(isa.(hist[:s], statetype(m)))
    @test last(collect(hist[:sp])) == 61
end

struct A end
@testset "preprocess" begin
    QuickPOMDPs.preprocess(::Type{A}) = Char 
    QuickPOMDPs.preprocess(::Val{:actiontype}, ::Type{A}) = Int 
    qm = QuickMDP(statetype=A, actiontype=A)
    @test statetype(qm) == Char
    @test actiontype(qm) == Int
    qp = QuickPOMDP(statetype=A, actiontype=A, obstype=Int)
    @test statetype(qp) == Char
    @test actiontype(qp) == Int
end

@testset "state action reward" begin
    qm = QuickMDP(states=1:3, actions=1:3, reward=(s, a)->0.0)
    @test StateActionReward(qm) isa FunctionSAR
    qm = QuickMDP(states=1:3, actions=1:3, reward=(s, a, sp)->0.0)
    @test StateActionReward(qm) isa LazyCachedSAR

    qp = QuickPOMDP(states=1:3, actions=1:3, observations=1:3, reward=(s, a)->0.0)
    @test StateActionReward(qp) isa FunctionSAR
    qp = QuickPOMDP(states=1:3, actions=1:3, observations=1:3, reward=(s, a, sp, o)->0.0)
    @test StateActionReward(qp) isa LazyCachedSAR
end

@testset "variable args" begin
    m = QuickMDP(states=1:3, actions=1:3, reward=(s, a)->0.0)
    @test @inferred(reward(m, 1, 2)) == 0.0
    @test @inferred(reward(m, 1, 2, 3)) == 0.0
    m = QuickPOMDP(states=1:3, actions=1:3, observations=1:3, reward=(s, a)->0.0)
    @test @inferred(reward(m, 1, 2)) == 0.0
    @test @inferred(reward(m, 1, 2, 3)) == 0.0
    @test @inferred(reward(m, 1, 2, 3, 1)) == 0.0
    m = QuickPOMDP(states=1:3, actions=1:3, observations=1:3, observation=(a, sp)->Deterministic(sp))
    @test rand(@inferred(observation(m, 2, 3))) == 3
    @test rand(@inferred(observation(m, 1, 2, 3))) == 3
    @test @inferred(obs_weight(m, 2, 3, 3)) == 1.0
    @test @inferred(obs_weight(m, 2, 3, 2)) == 0.0
    @test @inferred(obs_weight(m, 1, 2, 3, 3)) == 1.0
    @test @inferred(obs_weight(m, 1, 2, 3, 2)) == 0.0
end

@testset "#23" begin
    @test_throws MethodError QuickPOMDP(initialstate=:test)
end

@testset "action function" begin
    m = QuickMDP(actions=s->(1,2,3))
    @test actions(m, 1) == (1,2,3)
    @test_throws MissingQuickArgument actionindex(m, 1)
    m = QuickMDP(actions=Dict(1=>(1,2,3)))
    @test actions(m, 1) == (1,2,3)
    @test_throws MissingQuickArgument actionindex(m, 1)
end
