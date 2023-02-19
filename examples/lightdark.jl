using QuickPOMDPs
using POMDPTools
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
            return Deterministic(r+1) # transition to terminal state
        else
            return Deterministic(clamp(s+a, -r, r))
        end
    end,

    observation = (a, sp) -> Normal(sp, abs(sp - light_loc) + 0.0001),

    reward = function (s, a)
        if a == 0
            return s == 0 ? 100 : -100
        else
            return -1.0
        end
    end,

    initialstate = POMDPTools.Uniform(div(-r,2):div(r,2))
)
