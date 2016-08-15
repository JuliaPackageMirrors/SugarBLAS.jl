using SugarBLAS
using Base.Test

#scale!
@test macroexpand(:(@scale! X *= a)) == :(scale!(a, X))
@test macroexpand(:(@scale! X = a*X)) == :(scale!(a, X))
@test macroexpand(:(@blas! X *= a)) == :(scale!(a, X))
@test macroexpand(:(@blas! X = a*X)) == :(scale!(a, X))

#axpy!
@test macroexpand(:(@axpy! Y += a*X)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@axpy! Y = a*X + Y)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@axpy! Y = Y + a*X)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@axpy! Y = X + Y)) == :(Base.LinAlg.axpy!(1.0, X, Y))
@test macroexpand(:(@axpy! Y = Y + X)) == :(Base.LinAlg.axpy!(1.0, X, Y))
@test macroexpand(:(@axpy! Y += X)) == :(Base.LinAlg.axpy!(1.0, X, Y))
@test macroexpand(:(@blas! Y += a*X)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@blas! Y = a*X + Y)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@blas! Y = Y + a*X)) == :(Base.LinAlg.axpy!(a, X, Y))
@test macroexpand(:(@blas! Y = X + Y)) == :(Base.LinAlg.axpy!(1.0, X, Y))
@test macroexpand(:(@blas! Y = Y + X)) == :(Base.LinAlg.axpy!(1.0, X, Y))
@test macroexpand(:(@blas! Y += X)) == :(Base.LinAlg.axpy!(1.0, X, Y))

#copy!
@test macroexpand(:(@copy! X = Y)) == :(copy!(X, Y))
@test macroexpand(:(@blas! X = Y)) == :(copy!(X, Y))

#ger!
@test macroexpand(:(@ger! A += alpha*x*y')) == :(Base.LinAlg.BLAS.ger!(alpha,x,y,A))
@test macroexpand(:(@ger! A = alpha*x*y' + A)) == :(Base.LinAlg.BLAS.ger!(alpha,x,y,A))

#syr!
@test macroexpand(:(@syr! A[:U] += alpha*x*x.')) == :(Base.LinAlg.BLAS.syr!('U',alpha,x,A))
@test macroexpand(:(@syr! A[:L] += alpha*x*x.')) == :(Base.LinAlg.BLAS.syr!('L',alpha,x,A))
@test macroexpand(:(@syr! A[:U] = alpha*x*x.' + A)) == :(Base.LinAlg.BLAS.syr!('U',alpha,x,A))
@test macroexpand(:(@syr! A[:L] = alpha*x*x.' + A)) == :(Base.LinAlg.BLAS.syr!('L',alpha,x,A))

#syrk!
@test macroexpand(:(@syrk! C[:U] = alpha*A*A.' + beta*C)) == :(Base.LinAlg.BLAS.syrk!('U','N',alpha,A,beta,C))
@test macroexpand(:(@syrk! C[:U] = alpha*A*A.' + beta*C)) == :(Base.LinAlg.BLAS.syrk!('U','N',alpha,A,beta,C))
@test macroexpand(:(@syrk! C[:L] = alpha*A.'*A + beta*C)) == :(Base.LinAlg.BLAS.syrk!('L','T',alpha,A,beta,C))
@test macroexpand(:(@syrk! C[:L] = alpha*A.'*A + beta*C)) == :(Base.LinAlg.BLAS.syrk!('L','T',alpha,A,beta,C))

#her!
@test macroexpand(:(@her! A[:U] = alpha*x*x' + A)) == :(Base.LinAlg.BLAS.her!('U',alpha,x,A))
@test macroexpand(:(@her! A[:L] = alpha*x*x' + A)) == :(Base.LinAlg.BLAS.her!('L',alpha,x,A))
@test macroexpand(:(@her! A[:U] += alpha*x*x')) == :(Base.LinAlg.BLAS.her!('U',alpha,x,A))
@test macroexpand(:(@her! A[:L] += alpha*x*x')) == :(Base.LinAlg.BLAS.her!('L',alpha,x,A))

#herk!
@test macroexpand(:(@herk! C[:U] = alpha*A*A' + beta*C)) == :(Base.LinAlg.BLAS.herk!('U','N',alpha,A,beta,C))
@test macroexpand(:(@herk! C[:U] = alpha*A*A' + beta*C)) == :(Base.LinAlg.BLAS.herk!('U','N',alpha,A,beta,C))
@test macroexpand(:(@herk! C[:L] = alpha*A'*A + beta*C)) == :(Base.LinAlg.BLAS.herk!('L','T',alpha,A,beta,C))
@test macroexpand(:(@herk! C[:L] = alpha*A'*A + beta*C)) == :(Base.LinAlg.BLAS.herk!('L','T',alpha,A,beta,C))

#gbmv!
@test macroexpand(:(@gbmv! y = alpha*A[0:ku,h=2]*x + beta*y)) == :(Base.LinAlg.BLAS.gbmv!('N',2,0,ku,alpha,A,x,beta,y))
@test macroexpand(:(@gbmv! y = alpha*A[h=m,-kl:ku]*x + beta*y)) == :(Base.LinAlg.BLAS.gbmv!('N',m,kl,ku,alpha,A,x,beta,y))
@test macroexpand(:(@gbmv! y = alpha*A[h=2, 0:ku]'*x + beta*y)) == :(Base.LinAlg.BLAS.gbmv!('T',2,0,ku,alpha,A,x,beta,y))
@test macroexpand(:(@gbmv! y = alpha*A[kl:ku, h=m]'*x + beta*y)) == :(Base.LinAlg.BLAS.gbmv!('T',m,-kl,ku,alpha,A,x,beta,y))

#sbmv!
@test macroexpand(:(@sbmv! y = alpha*A[:U,0:k]*x + beta*y)) == :(Base.LinAlg.BLAS.sbmv!('U',k,alpha,A,x,beta,y))
@test macroexpand(:(@sbmv! y = beta*y + alpha*A[0:k,:U]*x)) == :(Base.LinAlg.BLAS.sbmv!('U',k,alpha,A,x,beta,y))
@test macroexpand(:(@sbmv! y = alpha*A[:L,0:k]*x + beta*y)) == :(Base.LinAlg.BLAS.sbmv!('L',k,alpha,A,x,beta,y))
@test macroexpand(:(@sbmv! y = beta*y + alpha*A[0:k,:L]*x)) == :(Base.LinAlg.BLAS.sbmv!('L',k,alpha,A,x,beta,y))

#gemm!
@test macroexpand(:(@gemm! C = alpha*A*B + beta*C)) == :(Base.LinAlg.BLAS.gemm!('N','N',alpha,A,B,beta,C))
@test macroexpand(:(@gemm! C = beta*C + 1.5*A*B')) == :(Base.LinAlg.BLAS.gemm!('N','T',1.5,A,B,beta,C))
@test macroexpand(:(@gemm! C = alpha*A'*B + beta*C)) == :(Base.LinAlg.BLAS.gemm!('T','N',alpha,A,B,beta,C))
@test macroexpand(:(@gemm! C = 3.4*C + alpha*A'*B')) == :(Base.LinAlg.BLAS.gemm!('T','T',alpha,A,B,3.4,C))

#gemv!
@test macroexpand(:(@gemv! y = alpha*A*x + beta*y)) == :(Base.LinAlg.BLAS.gemv!('N',alpha,A,x,beta,y))
@test macroexpand(:(@gemv! y = beta*y + 1.5*A'*x)) == :(Base.LinAlg.BLAS.gemv!('T',1.5,A,x,beta,y))
