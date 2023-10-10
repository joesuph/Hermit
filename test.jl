#import Pkg; 
#Pkg.add("SymbolicUtils")
#using SymbolicUtils


#TODO: Create global variable indexing so no conflicts are introduced.
#TODO: Fix how free variables are counted

#Formation rules
function meet(a::Expr,b::Expr)
    Expr(:pair,a,b)
end

function proj(a::Expr,b::Int)
    @assert a.head == :pair
    @assert b == 1 || b == 2
    a.args[b]
end

function matches(a::Symbol,b::Symbol)
    if a == b
        return true
    end
    if b == :_
        return true
    end
    return false
end

function matches(a::Expr,b::Symbol)
    if b == :_
        return true
    end
    return false
end

function matches(a::Expr,b::Expr)
    if a.head == b.head
        if length(a.args) == length(b.args)
            for i in 1:length(a.args)
                if !matches(a.args[i],b.args[i])
                    return false
                end
            end
            return true
        end
    end
    return false
end


mutable struct prop
    type::Symbol
    free_vars::Set{Symbol}
    universal_vars::Set{Symbol}
    args::Vector{prop}
    max_index::Int
    name::Symbol
end


function repr(a::prop)
    if a.type == :symbol 
        return string(a.name)
    elseif a.type == :imp
        return "$(repr(a.args[1])) → $(repr(a.args[2]))"
    elseif a.type == :prop
        return "($(chop(reduce(*,map(x->"$(repr(x)) ",a.args)))))"
    elseif a.type == :group
        return "($(reduce(*,map(x->"$(repr(x)), ", a.args))[begin:end-2]))"
    elseif a.type == :forall
        return "∀$(repr(a.args[1])):$(repr(a.args[2])),$(repr(a.args[3]))"
    elseif a.type == :entails
        return "$(repr(a.args[1])) ⊢ $(repr(a.args[2]))"
    end

    return string(a)
end



#meet(Expr(:a),Expr(:b)) |> println


prop(a,b,c,d,e) = prop(a,b,c,d,e,:default)

function group(args...)
    prop(:group,union(map(x->x.free_vars,args)...),union(map(x->x.universal_vars,args)...),[args...],max(map(x->x.max_index,args)...))
end

function atom(x::Symbol)
    prop(:symbol,Set(),Set(),[],0,x)
end

function prop(args::prop...)
    prop(:prop,union(map(x->x.free_vars,args)...),union(map(x->x.universal_vars,args)...),args,max(map(x->x.max_index,args)...))
end

function imp(a::prop,b::prop)
    prop(:imp,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a,b],max(a.max_index,b.max_index))
end

function abstract(a::Symbol,b::prop)
    if string(a)[1] == '_'
        return b
    end

    b = deepcopy(b)
    new_index = b.max_index+1

    for arg_i in 1:length(b.args)
        abstract_recur(a,b.args[arg_i],new_index)

        if b.args[arg_i].type == :symbol && string(b.args[arg_i].name)[1] == '_'
            b.free_vars = union(b.free_vars,Set([b.args[arg_i].name]))
        end
    end

    b.max_index = reduce(max,map(x->x.max_index,b.args))

    b
end

    
function abstract_recur(a::Symbol,exp::prop,new_index::Int)
    if exp.type == :entails
        return 
    elseif exp.type == :symbol
        if exp.name == a
            exp.name = Symbol("_x_$(new_index)")
            exp.max_index = new_index
        end
    else
        for arg_i in 1:length[exp.args]
            abstract_recur(a,exp.args[arg_i],new_index)
            exp.max_index = max(exp.max_index,exp.args[arg_i].max_index)

            if exp.args[arg_i].type == :symbol && string(exp.args[arg_i].name)[1] == '_'
                exp.free_vars = union(exp.free_vars,Set([exp.args[arg_i].name]))
            end

        end
    end
end

function insert(a::Symbol,b::prop,c::prop)
    if !in(a,b.free_vars)
        return nothing
    end

    b = deepcopy(b)

    for arg_i in 1:length(b.args)
        if b.args[arg_i].type == :symbol && b.args[arg_i].name == a
            b.args[arg_i] = c
        else
            insert_recur(a,b.args[arg_i],c)
        end
    end

    b.free_vars = reduce(union,map(x->x.free_vars,b.args),init = Set())
    b.max_index = reduce(max,map(x->x.max_index,b.args),init = 0)

    b
end

function insert_recur(a::Symbol,exp::prop,c::prop)
    println("H2")

    if exp.type == :entails
        return 
    else
        for arg_i in 1:length(exp.args)
            if exp.args[arg_i].type == :symbol && exp.args[arg_i].name == a
                exp.args[arg_i] = c
            else
                insert_recur(a,exp.args[arg_i],c)
            end
        end

        exp.free_vars = reduce(union,map(x->x.free_vars,exp.args), init = Set())
        exp.max_index = reduce(max,map(x->x.max_index,exp.args),init = 0)
    end

end

a = abstract(:a,group(atom(:a),atom(:b),atom(:a)))

a |> repr |> println

a.free_vars |> println

insert(:_x_1,a,group(atom(:c),atom(:d))) |> repr |> println