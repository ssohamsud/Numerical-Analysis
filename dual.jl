###############################
# 1. Define the Dual type
###############################
struct Dual
    value::Float64
    epsilon::Float64
end

###############################
# 2. Overload basic operations
###############################
import Base: +, -, *, /, sin, cos, exp, ^

# -- Addition --
function +(x::Dual, y::Dual)
    Dual(x.value + y.value, x.epsilon + y.epsilon)
end

function +(x::Dual, c::Float64)
    Dual(x.value + c, x.epsilon)
end
+(c::Float64, x::Dual) = x + c

# -- Subtraction --
function -(x::Dual, y::Dual)
    Dual(x.value - y.value, x.epsilon - y.epsilon)
end

function -(x::Dual, c::Float64)
    Dual(x.value - c, x.epsilon)
end
-(c::Float64, x::Dual) = Dual(c - x.value, -x.epsilon)

# -- Multiplication with another Dual --
function *(x::Dual, y::Dual)
    # (a + εb)*(c + εd) = a*c + ε(a*d + b*c)
    Dual(x.value * y.value,
         x.value * y.epsilon + x.epsilon * y.value)
end

# -- Multiplication with ANY Real (fixes Int * Dual) --
function *(x::Dual, c::Real)
    Dual(x.value * c, x.epsilon * c)
end

function *(c::Real, x::Dual)
    Dual(c * x.value, c * x.epsilon)
end

# -- Division --
function /(x::Dual, y::Dual)
    # (a + εb) / (c + εd) = (a/c) + ε((b*c - a*d)/(c^2))
    val = x.value / y.value
    eps = (x.epsilon * y.value - x.value * y.epsilon) / (y.value^2)
    Dual(val, eps)
end

function /(x::Dual, c::Real)
    Dual(x.value / c, x.epsilon / c)
end

function /(c::Real, x::Dual)
    val = c / x.value
    eps = -(c * x.epsilon) / (x.value^2)
    Dual(val, eps)
end

###############################
# 3. Overload common functions
###############################
function sin(x::Dual)
    # sin(a + εb) = sin(a) + ε(b*cos(a))
    Dual(sin(x.value), x.epsilon * cos(x.value))
end

function cos(x::Dual)
    Dual(cos(x.value), -x.epsilon * sin(x.value))
end

function exp(x::Dual)
    val = exp(x.value)
    Dual(val, x.epsilon * val)
end

###############################
# 4. Define exponentiation (^)
###############################
"""
    ^(x::Dual, n::Int)

Computes x^n for a Dual `x` and integer `n`.
"""
function ^(x::Dual, n::Int)
    if n == 0
        return Dual(1.0, 0.0)
    elseif n > 0
        result = Dual(1.0, 0.0)
        for _ in 1:n
            result = result * x
        end
        return result
    else
        # negative exponent
        pos_exp = abs(n)
        result = Dual(1.0, 0.0)
        for _ in 1:pos_exp
            result = result * x
        end
        return Dual(1.0, 0.0) / result
    end
end

###############################
# 5. Derivative function
###############################
"""
    derivative(f, x0)

Computes the derivative of `f` at `x0` using Dual numbers.

Example:
    f(x) = sin(x) + x^2
    derivative(f, 3.0)  # => derivative at x=3.0
"""
function derivative(f::Function, x0::Float64)
    # Evaluate f(Dual(x0, 1.0)) and return the epsilon part
    return f(Dual(x0, 1.0)).epsilon
end

###############################
# 6. Demonstration
###############################
println("Dual number differentiator loaded.")
println("Usage: f(x) = ... ; derivative(f, x_val)")

# Example function using an Int factor
f(x) = 3*x + sin(x)^2
d = derivative(f, 2.0)
println("f(x) = 3*x + sin(x)^2  => derivative at x=2.0 is ", d)

# Another example
g(x) = x^3 + exp(x)
d2 = derivative(g, 1.5)
println("g(x) = x^3 + e^x => derivative at x=1.5 is ", d2)
