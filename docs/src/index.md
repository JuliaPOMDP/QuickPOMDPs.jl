# QuickPOMDPs.jl

QuickPOMDPs is a package that makes defining Markov decision processes (MDPs) and partially observable Markov decision processes easy.

The models defined with QuickPOMDPs are compatible with [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) and can be used with any solvers from that ecosystem that are appropriate for the problem.
Defining a model with QuickPOMDPs does not require any object-oriented programming, so it may be 

QuickPOMDPs contains two interfaces:
1) The *Discrete Explicit Interface*, is suitable for problems with small discrete state, action, and observation spaces. This interface is pedagogically useful because each element of the ``(S, A, O, R, T, Z, \gamma)`` tuple for a POMDP and ``(S, A, R, T, \gamma)`` tuple for an MDP is defined explicitly in a straightforward manner. See the Discrete Explicit Interface page for more details.
2) The *Quick Interface* is much more flexible, exposing nearly all of the features of POMDPs.jl as constructor keyword arguments. See the Quick Interface page for more details.
