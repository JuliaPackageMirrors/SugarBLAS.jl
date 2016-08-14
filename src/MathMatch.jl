module MathMatch

export @match

iscommutative(op::Expr) = iscommutative(op.args[1])
iscommutative(op::Symbol) = _iscommutative(Val{op})

_iscommutative(::Type{Val{:(+)}}) = true
_iscommutative{T<:Val}(::Type{T}) = false

iscall(expr::Expr) = expr.head == :call

permutations(r::Range) = permutations(collect(r))
permutations(v::Vector) = @task permfactory(v)

function permfactory{T}(v::Vector{T})
    stack = Vector{Tuple{Vector{T}, Vector{T}}}()
    push!(stack, (Vector{T}(), v))
    while !isempty(stack)
        state = pop!(stack)
        taken = copy(state[1])
        left = copy(state[2])
        isempty(left) && (produce(taken); continue)
        for i in 1:length(left)
            new_state = (push!(copy(taken), left[i]), vcat(left[1:i-1],left[i+1:end]))
            push!(stack, new_state)
        end
    end
end

function clear!(d::Dict)
    for key in keys(d)
        delete!(d, key)
    end
end

#Overwrite d
#Returns false if successfull, true otherwise
function conflictadd!(d::Dict, s::Symbol, v)
    haskey(d,s) && (d[s] != v) && return true
    d[s] = v
    false
end

function partialmatch(expr::Expr, formula::Expr)
    samehead = (expr.head == formula.head)
    samelen = length(expr.args) == length(formula.args)
    (samehead & samelen) || return false
    _partialmatch(Val{iscall(expr)}, expr, formula)
end

_partialmatch(::Type{Val{false}}, expr::Expr, formula::Expr) = true
_partialmatch(::Type{Val{true}}, expr::Expr, formula::Expr) = expr.args[1]==formula.args[1]

function match_args(symbols::Dict, expr::Expr, formula::Expr)
    offset = iscall(expr) ? 1 : 0
    _match_args(Val{iscommutative(expr)}, offset, symbols, expr, formula)
end

function _match_args(::Type{Val{false}}, offset, symbols, expr, formula)
    eargs, margs = expr.args, formula.args
    for i in 1+offset:length(eargs)
        match(symbols, eargs[i], margs[i]) || return false
    end
    true
end
function _match_args(::Type{Val{true}}, offset, symbols, expr, formula)
    eargs, margs = expr.args, formula.args
    n = length(eargs)-offset
    for perm in permutations(1+offset:length(eargs))
        success = true
        d = copy(symbols)
        for i in 1:n
            match(d, eargs[i+offset], margs[perm[i]]) || (success=false; break)
        end
        success && (merge!(symbols, d); return true)
    end
    false
end

match(symbols::Dict, expr, s::Symbol) = !conflictadd!(symbols, s, expr)
function match(symbols::Dict, expr::Expr, formula::Expr)
    partialmatch(expr, formula) || return false
    match_args(symbols, expr, formula)
end
match(::Dict, expr, formula::Expr) = false

macro match(expr, formula)
    symbols = Dict{Symbol, Any}()
    matchto = "$formula"
    esc(quote
        $clear!($symbols)
        if $match($symbols, $expr, parse($matchto))
            Nullable($symbols)
        else
            Nullable()
        end
    end)
end

end
