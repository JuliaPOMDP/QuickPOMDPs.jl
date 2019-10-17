@testset "Quick" begin
    qm = QuickMDP(statetype=Int, actiontype=Int)
    @test statetype(qm) == Int
    @test actiontype(qm) == Int
    @test discount(qm) == 1.0
end
