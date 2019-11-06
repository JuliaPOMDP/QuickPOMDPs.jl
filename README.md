# QuickPOMDPs

[![Build Status](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/QuickPOMDPs.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaPOMDP/QuickPOMDPs.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaPOMDP/QuickPOMDPs.jl?branch=master)
[![codecov.io](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaPOMDP/QuickPOMDPs.jl?branch=master)

Simplified interfaces for specifying [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) models.

The package contains the two interfaces below. Please see the documentation for more information on each.

- The **Discrete Explicit Interface**, is suitable for problems with small discrete state, action, and observation spaces. This interface is pedagogically useful because each element of the ``(S, A, O, R, T, Z, \gamma)`` tuple for a POMDP and ``(S, A, R, T, \gamma)`` tuple for an MDP is defined explicitly in a straightforward manner. **Example:** [todo: link to docs]
- The **Quick Interface** is much more flexible, exposing nearly all of the features of POMDPs.jl as constructor keyword arguments. **Example:** [examples/mountaincar_with_visualization.jl](/examples/mountaincar_with_visualization.jl)

The package can also be used from **[Python](https://www.python.org)** via [pyjulia](https://github.com/JuliaPy/pyjulia). See [examples/tiger.py](https://github.com/JuliaPOMDP/QuickPOMDPs.jl/blob/master/examples/tiger.py) for an example.
