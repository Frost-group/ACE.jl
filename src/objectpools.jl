
# This is inspired by 
#      https://github.com/tpapp/ObjectPools.jl
# but considerably simplified and now evolved 

module ObjectPools

export acquire!, release!, ArrayPool



struct ArrayPool
    arrays::Dict{Any, Vector}

    ArrayPool() = new(Dict{Any, Vector}())
end

"""
    acquire!(pool, T, dims)

Return a yet unused `Array{T}` from `pool` with dimension `dims`. 
"""
function acquire!(pool::ArrayPool, ::Type{T}, dims::NTuple{N, Int}) where {T,N}
    key = (T, dims)
    if haskey( pool.arrays, key )
        _pl = pool.arrays[key]::Vector{Array{T, N}}
        if length(_pl) > 0 
            return pop!(_pl)
        end
    end 
    return Array{T, N}(undef, dims)
end

function release!(pool::ArrayPool, x::Array{T, N}) where {T, N}
    key = (T, size(x))
    if haskey( pool.arrays, key )
        _pl = pool.arrays[key]::Vector{Array{T, N}}
        push!(_pl, x)
    else 
        pool.arrays[key] = [x, ] 
    end
    return nothing 
end



export HomogeneousVectorPool

struct HomogeneousVectorPool{T}
    arrays::Dict{Int, Vector{Vector{T}}}

    HomogeneousVectorPool{T}() where {T} = new(Dict{Int, Vector{Vector{T}}}())
end

function acquire!(pool::HomogeneousVectorPool{T}, len::Integer) where {T}
    key = len
    if haskey( pool.arrays, key )
        _pl = pool.arrays[key]
        if length(_pl) > 0 
            return pop!(_pl)
        end
    end 
    return Vector{T}(undef, len)
end

function release!(pool::HomogeneousVectorPool, x::Vector{T}) where {T}
    key = length(x)
    if haskey( pool.arrays, key )
        _pl = pool.arrays[key]
        push!(_pl, x)
    else 
        pool.arrays[key] = [x, ] 
    end
    return nothing 
end



export StaticVectorPool

struct StaticVectorPool{T}
    arrays::Vector{Vector{T}}

    StaticVectorPool{T}() where {T} = new( Vector{T}[ ] )
end

acquire!(pool::StaticVectorPool{T}, len::Integer, ::Type{T}) where {T} = 
        acquire!(pool, len)


function acquire!(pool::StaticVectorPool{T}, len::Integer) where {T}
    if length(pool.arrays) > 0     
        x = pop!(pool.arrays)
        if len > length(x) 
            resize!(x, len)
        end 
        return x 
    else
        return Vector{T}(undef, len)
    end
end

function release!(pool::StaticVectorPool{T}, x::Vector{T}) where {T}
    push!(pool.arrays, x)
    return nothing 
end

# fallbacks 

acquire!(pool::StaticVectorPool{T}, len::Integer, S::Type{T1}) where {T, T1} = 
        Vector{S}(undef, len)

release!(pool::StaticVectorPool{T}, x::AbstractVector) where {T} = 
    nothing 


end # module
