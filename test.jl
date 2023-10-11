all_symbols = Set()
addSymbol(x::Symbol) = (global all_symbols = union(all_symbols,Set([x])))
symbol_index = 0
nextIndex() = (global symbol_index += 1; symbol_index) 

#TODO: Fix how free variables are counted
#TODO: Add abstraction over any prop
#TODO: Add abstraction over any arg_indices
#TODO handle free variables
#TODO: handle universal_vars
#TODO: Handle introduced variables

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


mutable struct Prop
    type::Symbol
    free_vars::Set{Symbol}
    universal_vars::Set{Symbol}
    args::Vector{Prop}
    name::Symbol
end

#=
function match_tran(a::Prop,b::Prop)
    if a.type == :matches && b.type == :matches
        if matches(a.args[2],b.args[1])
            return Prop(:matches,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a.args[1],b.args[2]])
        end
    end
end
=#
function create_match(a::Prop,b::Prop)
    if a.type == :matches && b.type == :inserts
        if a.args[2] == b.args[4]
            return Prop(:matches,union(a.args[1].free_var,b.args[2].free_var),union(a.args[1].universal_vars,b.args[2].universal_vars),[a.args[1],b.args[2]])
        end
    end
    
    #=
    if a.type == b.type && a.name == b.name
        if length(a.args) == length(b.args)
            for i in 1:length(a.args)
                if !matches(a.args[i],b.args[i])
                    return nothing
                end
            end
            return Prop(:matches,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a,b])
        end
        
    end
    =#



    return nothing
end


function repr(a::Prop)
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
    elseif a.type == :inserts
        return "[$(repr(a.args[1]))/$(repr(a.args[3]))]$(repr(a.args[2])) = $(repr(a.args[4]))"
    elseif a.type == :matches
        return "$(repr(a.args[1])) -> $(repr(a.args[2]))"
    end

    return string(a)
end

Prop(a,b,c,d) = Prop(a,b,c,d,:default)

function get_free_vars(x::Prop)
    free_vars = Set()
    for arg_i in 1:length(x.args)
        if x.args[arg_i].type == :symbol && string(x.args[arg_i].name)[1] == '_'
            push!(free_vars,x.args[arg_i].name)
        else
            free_vars = union(free_vars,get_free_vars(x.args[arg_i]))
        end
    end
    return free_vars
end

# Formation Rules

function group(args...)
    c = Prop(:group,union(map(x->x.free_vars,args)...),union(map(x->x.universal_vars,args)...),[args...])
    c.free_vars = get_free_vars(c)
    c
end

function atom(x::Symbol,add = true)
    if add
        addSymbol(x)
    end
    Prop(:symbol,Set(),Set(),[],x)
end

function Prop(args...)
    args = [args...]
    args = map(x->typeof(x)==Symbol ? atom(x) : x,args)
    c = Prop(:prop,union(map(x->x.free_vars,args)...),union(map(x->x.universal_vars,args)...),args)
    c.free_vars = get_free_vars(c)
    c
end


function imp(a::Prop,b::Prop)
    c = Prop(:imp,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a,b])
    c.free_vars = get_free_vars(c)
    c
end

function imp(a::Symbol,b::Symbol)
    a = atom(a)
    b = atom(b)
    imp(a,b)
end

function abstract(a::Symbol,b::Prop)
    if string(a)[1] == '_'
        return b
    end

    b = deepcopy(b)
    new_index = nextIndex()

    for arg_i in 1:length(b.args)
        abstract_recur(a,b.args[arg_i],new_index)

        if b.args[arg_i].type == :symbol && string(b.args[arg_i].name)[1] == '_'
            b.free_vars = union(b.free_vars,Set([b.args[arg_i].name]))
        end
    end

    b
end

    
function abstract_recur(a::Symbol,exp::Prop,new_index::Int)
    if exp.type == :entails
        return 
    elseif exp.type == :symbol
        if exp.name == a
            exp.name = Symbol("_x_$(new_index)")
        end
    else
        for arg_i in 1:length[exp.args]
            abstract_recur(a,exp.args[arg_i],new_index)

            if exp.args[arg_i].type == :symbol && string(exp.args[arg_i].name)[1] == '_'
                exp.free_vars = union(exp.free_vars,Set([exp.args[arg_i].name]))
            end

        end
    end
end

function insert(a::Symbol,b::Prop,c::Prop)
    if !in(a,b.free_vars)
        return nothing
    end
    og = b
    b = deepcopy(b)

    for arg_i in 1:length(b.args)
        if b.args[arg_i].type == :symbol && b.args[arg_i].name == a
            b.args[arg_i] = c
        else
            insert_recur(a,b.args[arg_i],c)
        end
    end

    b.free_vars = reduce(union,map(x->x.free_vars,b.args),init = Set())

    group(b,Prop(:inserts,Set(),Set(),[c,og,atom(a),b]))
end

function insert_recur(a::Symbol,exp::Prop,c::Prop)
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
    end

end

function proj(a::Prop,b::Int)
    @assert b <= length(a.args)
    return a.args[b]
end

function introduce(a::Symbol,b::Prop,c::Prop)
    if string(a)[end] != '_' || c.type != :symbol ||  in(c.name,all_symbols) || length(b.free_vars)>0 
        return nothing
    end
    b = deepcopy(b)

    for arg_i in 1:length(b.args)
        if b.args[arg_i].type == :symbol && b.args[arg_i].name == a
            b.args[arg_i] = c
            addSymbol(c.name)
        else
            introduce_recur(a,b.args[arg_i],c)
        end
    end

    b.free_vars = reduce(union,map(x->x.free_vars,b.args),init = Set())

    b
end

function introduce_recur(a::Symbol,exp::Prop,c::Prop)
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
    end

end

introduce(a::Symbol,b::Prop,c::Symbol) = introduce(a,b,atom(c,false))


#Entailment
function mp(ant::Prop,implication::Prop)
    #check if they already match
    ant_match_with_implication = create_match(ant,implication.args[1])
    if ant_match_with_implication !== nothing
        return Prop(:entails,union(ant_match_with_implication[2].free_vars,implication.args[2].free_vars),union(ant_match_with_implication[2].universal_vars,implication.args[2].universal_vars),[group(ant,implication),implication.args[2]])
    end
    
    #check if they match after inserting
    if length(implication.free_vars) != 1 return nothing end
    ant_insert_into_implication = insert(collect(implication.free_vars)[1],implication,ant).args[1]
    return Prop(:entails, ant_insert_into_implication.args[2].free_vars,Set(),[group(ant,implication), ant_insert_into_implication.args[2]])

end

function mp(a::Prop)
    if a.type == :group && length(a.args) ==2
        return mp(a.args[1],a.args[2])
    end
end

#=
function e_tran(a::Prop,b::Prop)
    if a.type == :entails && b.type == :entails && matches(a.args[1],b.args[1])
        return Prop(:entails,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars), [a.args[1],group(a.args[2],b.args[2])])
    end

    if a.type == :entails && b.type == :entails && matches(a.args[2],b.args[1])
        return Prop(:entails,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a.args[1],b.args[2]])
    end
    return nothing
end

function e_tran(a::Prop)
    if a.type == :group && length(a.args) ==2
        return e_tran(a.args[1],a.args[2])
    end
end

function e_proj(a::Prop,b::Prop)
    if a.type == :group && in(b,a.args)
        return Prop(:entails,union(a.free_vars,b.free_vars),union(a.universal_vars,b.universal_vars),[a.args[1],b.args[2]])    
    end
    return nothing
end
=#
#Natural Numbers
zero = atom(:zero)
isNum = atom(:isNum)
zeroIsNum = Prop(zero,isNum)

context = group(zero,isNum,zeroIsNum)

nextNum = imp(Prop(:_x, isNum),group(Prop(:y_, isNum),Prop(:_x, :lt, :y_)))

insert(:_x,nextNum,zero) |> repr |> println

#Scratch

res = mp(zeroIsNum,nextNum) 

introduce(:y_,res,:one) |> repr |> println

