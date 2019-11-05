@testset "Quick" begin
    qm = QuickMDP(statetype=Int, actiontype=Int)
    @test statetype(qm) == Int
    @test actiontype(qm) == Int
    @test discount(qm) == 1.0
    @test isterminal(qm, 1) == false
    @test_throws MissingQuickArgument transition(qm, 1, 1)
    @test_throws MissingQuickArgument initialstate_distribution(qm)
    @test_throws MissingQuickArgument reward(qm, 1, 1, 1)
    @test_throws MissingQuickArgument initialstate(qm, MersenneTwister(2))
    @test_throws MissingQuickArgument states(qm)
    @test_throws MissingQuickArgument actions(qm)
    @test_throws MissingQuickArgument stateindex(qm, 1)
    @test_throws MissingQuickArgument actionindex(qm, 1)
 
    qp = QuickPOMDP(obstype=Int)
    @test obstype(qp) == Int
    @test statetype(qp) == Any
    @test actiontype(qp) == Any
    @test discount(qp) == 1.0
    @test isterminal(qp, 1) == false
    @test_throws MissingQuickArgument transition(qp, 1, 1)
    @test_throws MissingQuickArgument observation(qp, 1, 1)
    @test_throws MissingQuickArgument initialstate_distribution(qp)
    @test_throws MissingQuickArgument reward(qp, 1, 1, 1)
    @test_throws MissingQuickArgument initialstate(qp, MersenneTwister(20))
    @test_throws MissingQuickArgument initialobs(qp, 1, MersenneTwister(1))
    @test_throws MissingQuickArgument states(qp)
    @test_throws MissingQuickArgument actions(qp)
    @test_throws MissingQuickArgument observations(qp)
    @test_throws MissingQuickArgument stateindex(qp, 1)
    @test_throws MissingQuickArgument actionindex(qp, 1)
    @test_throws MissingQuickArgument obsindex(qp, 1)
    
    @test_throws MissingQuickArgument gen(DDNOut(:sp,:o,:r), qp, 1, 1, MersenneTwister(2))
end

@testset "Mountan Car" begin
    mountaincar = begin
        include("../examples/mountaincar.jl")
    end
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
    hist = simulate(sim, mountaincar, energize)
    @test maximum(hist[:r]) == 100.0
    @test all(isa.(hist[:s], statetype(mountaincar)))
    @test last(collect(hist[:sp]))[1] > 0.5
end

@testset "Mountan Car Visualization" begin
    m = begin
        include("../examples/mountaincar_with_visualization.jl")
    end
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
    hist = simulate(sim, m, energize)
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
    hist = simulate(sim, m, p)
    @test all(-100 .<= hist[:r] .<= 100)
    @test all(isa.(hist[:s], statetype(m)))
    @test last(collect(hist[:sp])) == 61
end
