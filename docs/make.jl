using Documenter
using QuickPOMDPs

makedocs(
    sitename = "QuickPOMDPs",
    format = Documenter.HTML(),
    modules = [QuickPOMDPs]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
