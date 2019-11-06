struct MissingQuickArgument <: Exception
    m::QuickModel
    name::Symbol
    types::Union{AbstractVector, Missing}
    also::AbstractVector
end

function MissingQuickArgument(m::QuickModel, name::Symbol; types=missing, also=[])
    return MissingQuickArgument(m, name, types, also)
end

function Base.showerror(io::IO, ex::MissingQuickArgument)
    if ex.m isa QuickMDP
        basetype = "QuickMDP"
    elseif ex.m isa QuickPOMDP
        basetype = "QuickPOMDP"
    else
        basetype = string(typeof(ex.m))
    end
    println(io, """
            No definition of "$(ex.name)" for a $basetype (id=$(id(ex.m))).

            Please specify it with a `$(ex.name)` keyword argument in the $basetype constructor.
            """)

    if !ismissing(ex.types)
        println(io, "Suggested types for the `$(ex.name)` keyword argument are:")
        for t in ex.types
            println(io, "    $t")
        end
        println(io)
    end

    if !isempty(ex.also)
        println(io, "Also consider the following keyword arguments (providing them may or may not fix the problem):")
        for a in ex.also
            println(io, "    $a")
        end
    end
end
