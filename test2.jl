struct phrase
    dictionary::Dict{Expr, Expr}
    expression::Expr
end

function phrase()
    phrase(Dict(), :())
end

function phrase(x::Expr)
    phrase(Dict(),x)
end





