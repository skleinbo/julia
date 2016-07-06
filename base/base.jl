# This file is a part of Julia. License is MIT: http://julialang.org/license

type SystemError <: Exception
    prefix::AbstractString
    errnum::Int32
    extrainfo
    SystemError(p::AbstractString, e::Integer, extrainfo) = new(p, e, extrainfo)
    SystemError(p::AbstractString, e::Integer) = new(p, e, nothing)
    SystemError(p::AbstractString) = new(p, Libc.errno())
end

type ParseError <: Exception
    msg::AbstractString
end

type ArgumentError <: Exception
    msg::AbstractString
end

#type UnboundError <: Exception
#    var::Symbol
#end

type KeyError <: Exception
    key
end

type MethodError <: Exception
    f
    args
    world::UInt
    MethodError(f::ANY, args::ANY, world::UInt) = new(f, args, world)
end
MethodError(f::ANY, args::ANY) = MethodError(f, args, 0)

type EOFError <: Exception end

type DimensionMismatch <: Exception
    msg::AbstractString
end
DimensionMismatch() = DimensionMismatch("")

type AssertionError <: Exception
    msg::AbstractString

    AssertionError() = new("")
    AssertionError(msg) = new(msg)
end

#Generic wrapping of arbitrary exceptions
#Subtypes should put the exception in an 'error' field
abstract WrappedException <: Exception

type LoadError <: WrappedException
    file::AbstractString
    line::Int
    error
end

type InitError <: WrappedException
    mod::Symbol
    error
end

ccall(:jl_get_system_hooks, Void, ())


==(w::WeakRef, v::WeakRef) = isequal(w.value, v.value)
==(w::WeakRef, v) = isequal(w.value, v)
==(w, v::WeakRef) = isequal(w, v.value)

function finalizer(o::ANY, f::ANY)
    if isimmutable(o)
        error("objects of type ", typeof(o), " cannot be finalized")
    end
    ccall(:jl_gc_add_finalizer_th, Void, (Ptr{Void}, Any, Any),
          Core.getptls(), o, f)
end
function finalizer{T}(o::T, f::Ptr{Void})
    @_inline_meta
    if isimmutable(T)
        error("objects of type ", T, " cannot be finalized")
    end
    ccall(:jl_gc_add_ptr_finalizer, Void, (Ptr{Void}, Any, Ptr{Void}),
          Core.getptls(), o, f)
end

finalize(o::ANY) = ccall(:jl_finalize_th, Void, (Ptr{Void}, Any,),
                         Core.getptls(), o)

gc(full::Bool=true) = ccall(:jl_gc_collect, Void, (Cint,), full)
gc_enable(on::Bool) = ccall(:jl_gc_enable, Cint, (Cint,), on)!=0

# used by interpolating quote and some other things in the front end
function vector_any(xs::ANY...)
    n = length(xs)
    a = Array{Any}(n)
    @inbounds for i = 1:n
        arrayset(a,xs[i],i)
    end
    a
end

immutable Nullable{T}
    isnull::Bool
    value::T

    Nullable() = new(true)
    Nullable(value::T, isnull::Bool=false) = new(isnull, value)
end
