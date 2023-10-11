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




mutable struct Prop
    type::Symbol
    free_vars::Set{Symbol}
    universal_vars::Set{Symbol}
    args::Vector{Prop}
    name::Symbol
end

function matchTest(a::Prop,b::Prop,info=[])
    info_dict = Dict()
    map(x->info_dict[x] =Dict(),info)

    if b.type == :symbol && string(b.name)[1] == '_'
        if in("fills", info) 
            if !haskey(info_dict["fills"],b.name) 
                info_dict["fills"][b.name] = a.name
            elseif info_dict["fills"][b.name] != a.name
                return (false,info_dict)
            end
        end
        return (true,info_dict)

    elseif a.type == :symbol && b.type == :symbol
        return (a.name == b.name,info_dict)
    
    elseif a.type == b.type && length(a.args) == length(b.args)
        for i in 1:length(a.args)
            match_results = matchTest(a.args[i],b.args[i],info)
            info_dict["fills"] = merge(info_dict["fills"],match_results[2]["fills"])
            if !match_results[1]
                return info_dict != Dict() ? (false,info_dict) : false
            end
        end

        if info_dict != Dict()
            return (true,info_dict)
        end

        return true
    end

    return false
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
    if a.type == :matches && b.type == :plugin
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
    elseif a.type == :plugin
        return "$(repr(a.args[2]))[$(repr(a.args[1])) := $(repr(a.args[3]))] = $(repr(a.args[4]))"
    elseif a.type == :matches
        return "$(repr(a.args[1])) -> $(repr(a.args[2]))"
    end

    return error("Type of Prop not recognized")
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



function plug_in(a::Prop,b::Prop)
    if length(b.free_vars) > 0
        return insert(collect(b.free_vars)[1],b,a)
    end
    return nothing
end

function plug_in_at(a::Prop,b::Prop,c::Symbol)
    return insert(c,b,a)
end

function insert(a::Symbol,b::Prop,c::Prop)
    @assert in(a,b.free_vars)

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

    group(b,Prop(:plugin,Set(),Set(),[c,og,atom(a),b]))
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

function introSymFromProp(symb::Symbol,p::Prop, start = true, og=nothing)
    if start 
        p = deepcopy(p) 
    end

    if p.type == :symbol && ((og === nothing && string(p.name)[end]== '_')|| p.name == og)
        og = p.name
        p.name = symb
    end

    for arg_i in 1:length(p.args)
        p.args[arg_i],og = introSymFromProp(symb,p.args[arg_i],false,og)
    end

    start ? p : (p,og) 
end


function introduce(a::Symbol,b::Prop,c::Prop)
    @assert string(a)[end] == '_' 
    @assert c.type == :symbol 
    @assert !in(c.name,all_symbols) 

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
function mp(antecedent::Prop, implication::Prop)
    match_test_results = matchTest(antecedent,implication.args[1],["fills"])

    if match_test_results[1]
        new_consequent = replacePropFromDict(implication.args[2],match_test_results[2]["fills"])
        return Prop(:entails,union(antecedent.free_vars,new_consequent.free_vars),union(antecedent.universal_vars,new_consequent.universal_vars),[group(antecedent,implication),new_consequent])    
    end
end

function replacePropFromDict(a::Prop,dict::Dict, start = true)
    if start
        a = deepcopy(a)
    end

    if a.type == :symbol
        if haskey(dict,a.name)
            a.name = dict[a.name]

        end
    end

    for arg_i in 1:length(a.args)
        a.args[arg_i] = replacePropFromDict(a.args[arg_i],dict,false)
    end

    a
end

function mp(a::Prop)
    @assert a.type == :group 
    @assert length(a.args) ==2
    return mp(a.args[1],a.args[2])

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


#Scratch
mp(zeroIsNum,nextNum)|> repr |> println

introSymFromProp(:one,mp(zeroIsNum,nextNum)) |> repr |> println

#introduce(:y_,res,:one) |> repr |> println

