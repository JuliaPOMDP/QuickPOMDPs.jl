@testset "Discrete Explicit Tiger" begin
    S = [:left, :right]
    A = [:left, :right, :listen]
    O = [:left, :right]
    γ = 0.95

    function T(s, a, sp)
        if a == :listen
            return s == sp
        else # a door is opened
            return 0.5 #reset
        end
    end

    function Z(a, sp, o)
        if a == :listen
            if o == sp
                return 0.85
            else
                return 0.15
            end
        else
            return 0.5
        end
    end

    function R(s, a)
        if a == :listen  
            return -1.0
        elseif s == a # the tiger was found
            return -100.0
        else # the tiger was escaped
            return 10.0
        end
    end

    m = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ)

    solver = FunctionSolver(x->:listen)
    policy = solve(solver, m)
    updater = DiscreteUpdater(m)

    rsum = 0.0
    for (s,b,a,o,r) in stepthrough(m, policy, updater, "s,b,a,o,r", max_steps=10)
        println("s: $s, b: $([pdf(b,s) for s in S]), a: $a, o: $o")
        rsum += r
    end
    println("Undiscounted reward was $rsum.")
    @test rsum == -10.0

    dm = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ,Deterministic(:left))
    @test initialstate(dm, Random.GLOBAL_RNG) == :left
    tm = DiscreteExplicitPOMDP(S,A,O,T,Z,R,γ,terminals=Set(S))
    @test isterminal(tm, initialstate(tm, Random.GLOBAL_RNG))

    for s in states(m)
        @test convert_s(statetype(m), convert_s(Vector{Float64}, s, m), m) == s
    end
    for a in actions(m)
        @test convert_a(actiontype(m), convert_a(Vector{Float64}, a, m), m) == a
    end
    for o in observations(m)
        @test convert_o(obstype(m), convert_o(Vector{Float64}, o, m), m) == o
    end
end

@testset "Discrete Explicit MDP" begin
    S = 1:5
    A = [-1, 1]
    γ = 0.95
    p₀ = Deterministic(1)

    function T(s, a, sp)
        if sp == clamp(s+a,1,5)
            return 0.8
        elseif sp == clamp(s-a,1,5)
            return 0.2
        else
            return 0.0
        end
    end

    function R(s, a)
        if s == 5
            return 1.0
        else
            return -1.0
        end
    end

    m = DiscreteExplicitMDP(S,A,T,R,γ)
    m = DiscreteExplicitMDP(S,A,T,R,γ,p₀)
    m = DiscreteExplicitMDP(S,A,T,R,γ,p₀,terminals=Set(5))
    @test isterminal(m, 5)

    solver = FunctionSolver(x->1)
    policy = solve(solver, m)

    rsum = 0.0
    for (s,a,r) in stepthrough(m, policy, "s,a,r", max_steps=10)
        println("s: $s, a: $a")
        rsum += r
    end
    println("Undiscounted reward was $rsum.")

    for s in states(m)
        @test convert_s(statetype(m), convert_s(Vector{Float64}, s, m), m) == s
    end
    for a in actions(m)
        @test convert_a(actiontype(m), convert_a(Vector{Float64}, a, m), m) == a
    end
end

@testset "convert Number POMDP" begin
    s = [1,47]
    T(s, a, sp) = s == sp
    Z(a, sp, o) = o == sp
    R(s, a) = 1.0
    m = DiscreteExplicitPOMDP(s,s,s,T,Z,R,0.95)
    for s in states(m)
        @test convert_s(statetype(m), convert_s(Vector{Float64}, s, m), m) == s
    end
    for a in actions(m)
        @test convert_a(actiontype(m), convert_a(Vector{Float64}, a, m), m) == a
    end
    for o in observations(m)
        @test convert_o(obstype(m), convert_o(Vector{Float64}, o, m), m) == o
    end
end

@testset "convert Vector POMDP" begin
    s = [[1,2],[3,4]]
    T(s, a, sp) = s == sp
    Z(a, sp, o) = o == sp
    R(s, a) = 1.0
    m = DiscreteExplicitPOMDP(s,s,s,T,Z,R,0.95)
    for s in states(m)
        @test convert_s(statetype(m), convert_s(Vector{Float64}, s, m), m) == s
    end
    for a in actions(m)
        @test convert_a(actiontype(m), convert_a(Vector{Float64}, a, m), m) == a
    end
    for o in observations(m)
        @test convert_o(obstype(m), convert_o(Vector{Float64}, o, m), m) == o
    end
end
