using Documenter
using QuickPOMDPs

makedocs(
    sitename = "QuickPOMDPs",
    format = Documenter.HTML(),
    modules = [QuickPOMDPs],
    pages = ["index.md",
             "discrete_explicit.md",
             "quick.md"
            ]
)

deploydocs(
    repo = "github.com/JuliaPOMDP/QuickPOMDPs.jl.git"
)
