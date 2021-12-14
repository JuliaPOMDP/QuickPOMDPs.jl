using Documenter
using QuickPOMDPs

makedocs(
    sitename = "QuickPOMDPs",
    format = Documenter.HTML(),
    modules = [QuickPOMDPs],
    pages = ["index.md",
             "quick.md",
             "discrete_explicit.md",
            ]
)

deploydocs(
    repo = "github.com/JuliaPOMDP/QuickPOMDPs.jl.git"
)
