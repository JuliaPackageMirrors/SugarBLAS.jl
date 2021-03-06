__precompile__(true)
module SugarBLAS

export  @blas!
export  @scale!, @axpy!, @copy!, @ger!, @syr!, @syrk!,
        @her!, @herk!, @gbmv!, @sbmv!, @gemm!, @gemv!,
        @symm!, @symv!

include("Match/Match.jl")
using .Match

import Base: copy, abs, -

copy(s::Symbol) = s
-(expr) = Expr(:call, :-, expr)

function abs(ast)
    if @match(ast, -ast) | (ast == 0)
        ast
    else
        Expr(:call, :(-), ast)
    end
end

substracts(expr) = false
substracts(expr::Expr) = (expr.head == :call) & (expr.args[1] == :-)

char(s::Symbol) = string(s)[1]
function char(expr::Expr)
    (expr.head == :quote) || error("char doesn't support $(expr.head)")
    char(expr.args[1])
end

isempty(nl::Nullable) = nl.isnull

wrap(expr::Symbol) = QuoteNode(expr)
function wrap(expr::Expr)
    head = QuoteNode(expr.head)
    func = string(expr.args[1])
    :(Expr($head, parse($func), $(expr.args[2:end]...)))
end

function expand(expr::Expr)
    @match(expr, A += B) && return :($A = $A + $B)
    @match(expr, A -= B) && return :($A = $A - $B)
    expr
end

macro call(expr::Expr)
    esc(:(esc($(wrap(expr)))))
end

macro switch(expr::Expr)
    (expr.head == :block) || error("@switch statement must be followed by `begin ... end`")
    lines = filter(expr::Expr -> expr.head != :line, expr.args)
    failproof(s) = s
    failproof(s::Char) = string("'",s,"'")
    line = lines[1]
    exec = "if $(line.args[1])\n$(failproof(line.args[2]))\n"
    for line in lines[2:end-1]
        (line.head == :line) && continue
        line.head == :(=>) || error("Each condition must be followed by `=>`")
        exec *= "elseif $(line.args[1])\n$(failproof(line.args[2]))\n"
    end
    line = lines[end]
    exec *= (line.args[1] == :otherwise) && ("else\n$(failproof(line.args[2]))\n")
    exec *= "end"
    esc(parse(exec))
end

###########
# Mutable #
###########

#Must be ordered from most to least especific formulas
macro blas!(expr::Expr)
    expr = expand(expr)
    @switch begin
        @match(expr, X *= a)        => @call scale!(a,X)
        @match(expr, X = a*X)       => @call scale!(a,X)
        @match(expr, Y = Y - a*X)   => @call Base.LinAlg.axpy!(-a,X,Y)
        @match(expr, Y = Y - X)     => @call Base.LinAlg.axpy!(-1.0,X,Y)
        @match(expr, Y = a*X + Y)   => @call Base.LinAlg.axpy!(a,X,Y)
        @match(expr, Y = X + Y)     => @call Base.LinAlg.axpy!(1.0,X,Y)
        @match(expr, X = Y)         => @call copy!(X, Y)
        otherwise                   => error("No match found")
    end
end

macro copy!(expr::Expr)
    @switch begin
        @match(expr, X = Y) => @call copy!(X,Y)
        otherwise           => error("No match found")
    end
end

macro scale!(expr::Expr)
    @switch begin
        @match(expr, X *= a)    => @call scale!(a,X)
        @match(expr, X = a*X)   => @call scale!(a,X)
        otherwise               => error("No match found")
    end
end

macro axpy!(expr::Expr)
    expr = expand(expr)
    @switch begin
        @match(expr, Y = Y - a*X)   => @call(Base.LinAlg.axpy!(-a,X,Y))
        @match(expr, Y = Y - X)     => @call Base.LinAlg.axpy!(-1.0,X,Y)
        @match(expr, Y = a*X + Y)   => @call Base.LinAlg.axpy!(a,X,Y)
        @match(expr, Y = X + Y)     => @call Base.LinAlg.axpy!(1.0,X,Y)
        otherwise                   => error("No match found")
    end
end

macro ger!(expr::Expr)
    expr = expand(expr)
    f = @switch begin
        @match(expr, A = alpha*x*y' + A)    => identity
        @match(expr, A = A - alpha*x*y')    => (-)
        otherwise                           => error("No match found")
    end
    @call Base.LinAlg.BLAS.ger!(f(alpha),x,y,A)
end

macro syr!(expr::Expr)
    expr = expand(expr)
    @match(expr, A[uplo] = right) || error("No match found")
    c = char(uplo)
    f = @switch begin
        @match(right, alpha*x*x.' + Y)  => identity
        @match(right, Y - alpha*x*x.')  => (-)
        otherwise                       => error("No match found")
    end
    (@match(Y, Y[uplo]) && (Y == A)) || (Y == A) || error("No match found")
    @call Base.LinAlg.BLAS.syr!(c,f(alpha),x,A)
end

macro syrk!(expr::Expr)
    expr = expand(expr)
    @match(expr, C[uplo] = right) || error("No match found")
    c = char(uplo)
    f = @switch begin
        @match(right, alpha*X*Y + D)    => identity
        @match(right, D - alpha*X*Y)    => (-)
        otherwise                       => error("No match found")
    end
    trans = @switch begin
        @match(X, A.') && (Y == A)  => 'T'
        @match(Y, A.') && (X == A)  => 'N'
        otherwise                   => error("No match found")
    end
    @match(D, beta*D) || (beta = 1.0)
    (@match(D, D[uplo]) && (C == D)) || (C == D) || error("No match found")
    @call Base.LinAlg.BLAS.syrk!(c,trans,f(alpha),A,beta,C)
end

macro her!(expr::Expr)
    expr = expand(expr)
    @match(expr, A[uplo] = right) || error("No match found")
    c = char(uplo)
    f = @switch begin
        @match(right, alpha*x*x' + Y)   => identity
        @match(right, Y - alpha*x*x')   => (-)
        otherwise                       => error("No match found")
    end
    (@match(Y, Y[uplo]) && (Y == A)) || (Y == A) || error("No match found")
    @call Base.LinAlg.BLAS.her!(c,f(alpha),x,A)
end

macro herk!(expr::Expr)
    expr = expand(expr)
    @match(expr, C[uplo] = right) || error("No match found")
    c = char(uplo)
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*X*Y + D)    => identity
        @match(right, D - alpha*X*Y)    => (-)
        otherwise                       => error("No match found")
    end
    trans = @switch begin
        @match(X, A') && (Y == A)   =>  'T'
        @match(Y, A') && (X == A)   =>  'N'
        otherwise                   =>  error("No match found")
    end
    @match(D, beta*D) || (beta = 1.0)
    (@match(D, D[uplo]) && (C == D)) || (C == D) || error("No match found")
    @call Base.LinAlg.BLAS.herk!(c,trans,f(alpha),A,beta,C)
end

macro gbmv!(expr::Expr)
    expr = expand(expr)
    @match(expr, y = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*Y*x + w)    => identity
        @match(right, w - alpha*Y*x)    => (-)
        otherwise                       => error("No match found")
    end
    trans = @match(Y, Y') ? 'T' : 'N'
    @match(Y, A[kl:ku,h=m])
    @match(w, beta*w) || (beta = 1.0)
    (@match(w, w[uplo]) && (y == w)) || (y == w) || error("No match found")
    @call Base.LinAlg.BLAS.gbmv!(trans,m,abs(kl),ku,f(alpha),A,x,beta,y)
end

macro sbmv!(expr::Expr)
    expr = expand(expr)
    @match(expr, y = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*A[0:k,uplo]*x + w)  => identity
        @match(right, w - alpha*A[0:k,uplo]*x)  => (-)
        otherwise                               => error("No match found")
    end
    c = char(uplo)
    @match(w, beta*w) || (beta = 1.0)
    (@match(w, w[uplo]) && (y == w)) || (y == w) || error("No match found")
    @call Base.LinAlg.BLAS.sbmv!(c,k,f(alpha),A,x,beta,y)
end

macro gemm!(expr::Expr)
    expr = expand(expr)
    @match(expr, C = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*A*B + D)    => identity
        @match(right, D - alpha*A*B)    => (-)
        otherwise                       => error("No match found")
    end
    tA = @match(A, A') ? 'T' : 'N'
    tB = @match(B, B') ? 'T' : 'N'
    @match(D, beta*D) || (beta = 1.0)
    (@match(D, D[uplo]) && (C == D)) || (C == D) || error("No match found")
    @call Base.LinAlg.BLAS.gemm!(tA,tB,f(alpha),A,B,beta,C)
end

macro gemv!(expr::Expr)
    expr = expand(expr)
    @match(expr, y = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*A*x + w)  => identity
        @match(right, w - alpha*A*x)  => (-)
        otherwise                         => error("No match found")
    end
    tA = @match(A, A') ? 'T' : 'N'
    @match(w, beta*w) || (beta = 1.0)
    (@match(w, w[uplo]) && (y == w)) || (y == w) || error("No match found")
    @call Base.LinAlg.BLAS.gemv!(tA,f(alpha),A,x,beta,y)
end

macro symm!(expr::Expr)
    expr = expand(expr)
    @match(expr, C[uplo] = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*A*B + D)    => identity
        @match(right, D - alpha*A*B)    => (-)
        otherwise                       => error("No match found")
    end
    c = char(uplo)
    side = @switch begin
        @match(A, A[symm]) && (symm.args[1] == :symm)   => 'L'
        @match(B, B[symm]) && (symm.args[1] == :symm)   => 'R'
        otherwise                                       => error("No match found")
    end
    @match(D, beta*D) || (beta = 1.0)
    (@match(D, D[uplo]) && (C == D)) || (C == D) || error("No match found")
    @call Base.LinAlg.BLAS.symm!(side,c,f(alpha),A,B,beta,C)
end

macro symv!(expr::Expr)
    expr = expand(expr)
    @match(expr, y = right) || error("No match found")
    f = @switch begin #Right hand side must match one of these
        @match(right, alpha*A[uplo]*x + w)  => identity
        @match(right, w - alpha*A[uplo]*x)  => (-)
        otherwise                         => error("No match found")
    end
    c = char(uplo)
    @match(w, beta*w) || (beta = 1.0)
    (@match(w, w[uplo]) && (y == w)) || (y == w) || error("No match found")
    @call Base.LinAlg.BLAS.symv!(c,f(alpha),A,x,beta,y)
end

end
