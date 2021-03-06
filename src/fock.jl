module fock

import Base.==

using ..bases, ..states, ..operators, ..operators_sparse

export FockBasis, number, destroy, create, fockstate, coherentstate, qfunc


"""
Basis for a Fock space.

Arguments
---------

Nmin
    Minimal particle number included in this basis. By default it is zero, i.e.
    starting with the vacuum state.
Nmax
    Maximal particle number included in this basis.
"""
type FockBasis <: Basis
    shape::Vector{Int}
    Nmin::Int
    Nmax::Int
    function FockBasis(Nmin::Int, Nmax::Int)
        if Nmin < 0 || Nmax <= Nmin
            throw(DimensionMismatch())
        end
        new([Nmax-Nmin+1], Nmin, Nmax)
    end
end

FockBasis(Nmax::Int) = FockBasis(0, Nmax)


==(b1::FockBasis, b2::FockBasis) = b1.Nmin==b2.Nmin && b1.Nmax==b2.Nmax

"""
Number operator for the given Fock space.

Arguments
---------

b
    FockBasis of this operator.
"""
function number(b::FockBasis)
    N = b.Nmax-b.Nmin+1
    diag = Complex128[complex(x) for x=b.Nmin:b.Nmax]
    data = spdiagm(diag, 0, N, N)
    SparseOperator(b, data)
end

"""
Annihilation operator for the given Fock space.

Arguments
---------

b
    FockBasis of this operator.
"""
function destroy(b::FockBasis)
    N = b.Nmax-b.Nmin+1
    diag = Complex128[complex(sqrt(x)) for x=b.Nmin+1:b.Nmax]
    data = spdiagm(diag, 1, N, N)
    SparseOperator(b, data)
end

"""
Creation operator for the given Fock space.

Arguments
---------

b
    FockBasis of this operator.
"""
function create(b::FockBasis)
    N = b.Nmax-b.Nmin+1
    diag = Complex128[complex(sqrt(x)) for x=b.Nmin+1:b.Nmax]
    data = spdiagm(diag, -1, N, N)
    SparseOperator(b, data)
end

"""
Fock state for the given particle number.

Arguments
---------

b
    FockBasis for this state.
n
    Quantum number of the state.
"""
function fockstate(b::FockBasis, n::Int)
    @assert b.Nmin <= n <= b.Nmax
    basis_ket(b, n+1-b.Nmin)
end

"""
Coherent state :math:`| \\alpha \\rangle` for the given Fock basis.

Arguments
---------

b
    FockBasis for this state.
alpha
    Eigenvalue of annihilation operator.
"""
function coherentstate(b::FockBasis, alpha::Number)
    alpha = complex(alpha)
    x = zeros(Complex128, b.Nmax - b.Nmin + 1)
    if b.Nmin == 0
        x[1] = exp(-abs2(alpha)/2)
    else
        x[1] = exp(-abs2(alpha)/2)*alpha^b.Nmin/sqrt(factorial(b.Nmin))
    end
    for n=1:(b.Nmax-b.Nmin)
        x[n+1] = x[n]*alpha/sqrt(b.Nmin + n)
    end
    return Ket(b, x)
end


"""
Husimi Q representation :math:`\\frac{1}{\\pi} \\langle \\alpha | \\rho | \\alpha \\rangle`.
"""
function qfunc(rho::Operator, alpha::Complex128)
    psi = coherentstate(rho.basis_l, alpha)
    return real(dagger(psi)*rho*psi)/pi
end

function qfunc(rho::Operator, X::Vector{Float64}, Y::Vector{Float64})
    @assert rho.basis_l == rho.basis_r
    return Float64[qfunc(rho, complex(x,y)) for x=X, y=Y]
end

end # module
