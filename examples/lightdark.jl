using QuickPOMDPs
using POMDPModelTools
using Distributions

#=
The simple 1-D light dark problem from https://arxiv.org/pdf/1709.06196v6.pdf, section 5.2, or https://slides.com/zacharysunberg/defense-4#/39
=#

r = 60
light_loc = 10

simple_lightdark = QuickPOMDP(
    states = -r:r+1,                  # r+1 is a terminal state
    actions = [-10, -1, 0, 1, 10],
    discount = 0.95,
    isterminal = s -> !(s in -r:r),
    obstype = Float64,

    transition = function (s, a)
        if a == 0
            return SparseCat(r+1, 1.0)
        else
            return SparseCat(clamp(s+a, -r, r), 1.0)
        end
    end,

    observation = (s, a, sp) -> Normal(sp, abs(sp - light_loc) + 0.0001),

    reward = function (s, a, sp, o)
        if a == 0
            return s == 0 ? 100 : -100
        else
            return -1.0
        end
    end,

    initialstate_distribution = POMDPModelTools.Uniform(div(-r,2):div(-r,2))
)
