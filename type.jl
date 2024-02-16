#main file

#Convert code to symbol list including parentheses and bars
function parse(code::AbstractString)::Vector{String}
    code = replace(code,"("=>" ( ")
    code = replace(code,")"=>" ) ")
    code = replace(code, "|" => " | ")
    code = replace(code,"["=>" [ ")
    code = replace(code,"]"=>" ] ")
    code = replace(code,","=>" , ")
    code = replace(code,":="=>" := ")
    code = replace(code,r"\s+"=>" ")
    code = filter( (x) -> x != "", split(code," "))
    return code 
end



function check_outer_square_brackets(code::Vector{String})::Bool
    if code[1] == "[" && code[end] == "]"
        paren_count = 0
        for i in 1:length(code)
            if code[i] == "["
                paren_count += 1
            elseif code[i] == "]"
                paren_count -= 1
                if paren_count == 0 && i != length(code)
                    return false
                end
            end
        end
        return true
    end
    return false
end

#If symbol list is surronded by parentheses, remove them
function remove_outer_parentheses(code::Vector{String})::Vector{String}
    if code[1] == "(" && code[end] == ")"
        paren_count = 0
        for i in 1:length(code)
            if code[i] == "("
                paren_count += 1
            elseif code[i] == ")"
                paren_count -= 1
                if paren_count == 0 && i != length(code)
                    return code
                end
            end
        end
        return code[2:end-1]
    end
    return code
end

#Add outer parenthese if there aren't any
function add_outer_parentheses(code::Vector{String})::Vector{String}
    if code[1] == "(" && code[end] == ")"
        paren_count = 0
        for i in 1:length(code)
            if code[i] == "("
                paren_count += 1
            elseif code[i] == ")"
                paren_count -= 1
                if paren_count == 0 && i != length(code)
                    return ["(",code...,")"]
                end
            end
        end
        return code
    end
    return ["(",code...,")"]
end

#Group up text in parentheses
function group_parentheses(code::Vector{String})::Vector{String}
    paren_count = 0
    start = 0
    for i in 1:length(code)
        if code[i] == "("
            paren_count+= 1
            if paren_count == 1
                start = i
            end
        elseif code[i] == ")"
            paren_count -= 1
            if paren_count == 0
                code = [code[1:start-1]..., join(code[start:i],' '), code[i+1:end]...]
                return group_parentheses(code)
            end
        end
    end
    return code
end

function ungroup_parentheses(code::Vector{String})::Vector{String}
    for i in 1:length(code)
        if length(code[i]) > 1 && code[i][1] == '('
            code = [code[1:i-1]...,parse(code[i])..., code[i+1:end]...]
            return ungroup_parentheses(code)
        end
    end
    return code
end

#What do I need to add to handle commas?
#If commas occur not in a group then split on them and check that 


function checkMatches(code1::Vector{String},pattern::Vector{String}, get_vars = false)::Union{Bool, Tuple{Bool,Dict{String,String}}}
    #println("checking: ",code1," == ",pattern)
    
    matches = Dict{String,String}()

    #remove outer parenthesis
    pattern = remove_outer_parentheses(pattern)
    pattern_is_just_disjunction = check_outer_square_brackets(pattern)
    if pattern_is_just_disjunction
        code1 = add_outer_parentheses(code1)
    else
        code1 = remove_outer_parentheses(code1)
    end

    example_index = 1
    pattern_index = 1
    #Compare each term one by one
    while pattern_index <= length(pattern)
        #Compare code term and pattern term
        #if they don't match or have a speccial case return false
        if example_index > length(code1) || #pattern is longer than code
                (code1[example_index] != pattern[pattern_index] && #code doesn't match pattern
                pattern[pattern_index][1] != '_' && #pattern is not wildcard
                code1[end] != '_' &&      #code is not existential
                pattern[pattern_index][1] != '[')  #pattern is not disjunction

            return get_vars ? (false,matches) : false
        end
        #println("code1[example_index]: ",code1[example_index])
        #println("pattern[pattern_index]: ",pattern[pattern_index])

        #if the string is (, skip to the the closing )
        if code1[example_index] == "(" && pattern[pattern_index][1] == '_'
            paren_count = 1
            #Find the closing )
            for i in example_index+1:length(code1)
                if code1[i] == "("
                    paren_count += 1
                elseif code1[i] == ")"
                    paren_count -= 1
                    if paren_count == 0
                        #On the closing )
                        #Check if matches has a value for the pattern character 
                        if haskey(matches,pattern[pattern_index])
                            #If it does, check if it matches the code if not return false
                            if matches[pattern[pattern_index]] != join(code1[example_index:i], ' ')
                                return get_vars ? (false,matches) : false
                            end
                        else #If matches doesn't have a value then add it
                            matches[pattern[pattern_index]] = join(code1[example_index:i], ' ')
                        end
                        
                        example_index = i
                        break
                    end
                end
            end
        #Handle disjunctions
        elseif (code1[example_index] == "("  && pattern[pattern_index] == "[" )
            #Get the argument of the disjunction
            arg = ""
            paren_count = 1
            #Find the closing )
            for i in example_index+1:length(code1)
                if code1[i] == "("
                    paren_count += 1
                elseif code1[i] == ")"
                    paren_count -= 1
                    if paren_count == 0
                        arg = parse(join(code1[example_index:i], ' '))
                        example_index = i
                        break
                    end
                end
            end
            
            
            if arg == ""
                throw(ErrorException("Error: Disjunction argument not found either because no closing ']' was found or because the argument was empty"))
            end

            #Find the closing ]
            paren_count = 1
            for j in pattern_index+1:length(pattern)
                if pattern[j] == "["
                    paren_count += 1
                elseif pattern[j] == "]"
                    paren_count -= 1
                    if paren_count == 0
                        subpattern = join(pattern[pattern_index+1:j-1],' ')
                        subpatterns = [strip(pat) for pat in split(subpattern,"|")]
                        println("subpatterns: ",subpatterns)
                        passed = false
                        for pat in subpatterns
                            pat = parse(String(pat))
                            check_result = checkMatches(arg,pat,true)
                            if check_result[1]

                                matches = merge(matches,check_result[2])
                                passed = true
                                break
                            end
                        end

                        if passed
                            pattern_index = j
                            break
                        else
                            return get_vars ? (false,matches) : false
                        end
                    end
                end

            end

        #If pattern is a wildcard check if matches has a value for it or add it
        else
            if pattern[pattern_index][1] == '_'
                if haskey(matches,pattern[pattern_index])
                    if matches[pattern[pattern_index]] != code1[example_index]
                        return get_vars ? (false,matches) : false
                    end
                else
                    matches[pattern[pattern_index]] = code1[example_index]
                end
            end
        end
    

        example_index += 1
        pattern_index += 1
    end

    #Will this work?
    if example_index <= length(code1)
        return get_vars ? (false,matches) : false
    end

    return get_vars ? (true,matches) : true
end


#Given a code and a list of replacements, if any term is in 
function replace_vars(code::Vector{String}, matches::Dict{String,String})::Vector{String}
    for i in 1:length(code)
        if haskey(matches,code[i])
            code[i] = matches[code[i]]
        end
    end
    return code
end


function modus_ponens(code::Vector{String}, implication_pattern::Vector{String})::Vector{String}
    grouped_implication = group_parentheses(parse(join(implication_pattern, " ")))
    if "->" in grouped_implication && grouped_implication[2] != "->"
        premise = grouped_implication[1:findfirst(isequal("->"),grouped_implication)-1]
        conclusion = grouped_implication[findfirst(isequal("->"),grouped_implication)+1:end]
        grouped_implication = [add_outer_parentheses(premise)..., "->", add_outer_parentheses(conclusion)...]
        grouped_implication = group_parentheses(grouped_implication)
    end

    @assert grouped_implication[2] == "->"

    premise = parse(grouped_implication[1])

    match_result = checkMatches(code,premise,true)



    @assert match_result[1] == true

    conclusion = remove_outer_parentheses(parse(grouped_implication[3]))

    conclusion = replace_vars(conclusion,match_result[2])

    return conclusion
end

function proj(code::Vector{String}, index::Int)::Vector{String}
    return ungroup_parentheses(split_list_on_commas(code)[index])
end

function split_list_on_commas(code::Vector{String})::Vector{Vector{String}}
    separated_lists = []
    j = 1
    for i in 1:length(code)
        if code[i] == ","
            push!(separated_lists,code[j:i-1])
            j = i+1
        end
    end
    push!(separated_lists,code[j:end])
    return separated_lists
end


function assignment_to_match(code::Vector{String})::Dict{String,String}
    match = Dict{String,String}()
    
    code = group_parentheses(code)
    if ":=" in code
        assignment_index = findfirst(isequal(":="),code)
        variable = join(code[1:assignment_index-1]," ")
        value = code[assignment_index+1:end]
        match[variable] = join(value," ")
    end
    return match
end



#Add recursion over subexpressions and over commas
function replace_definitions(code::Vector{String}, definitions::Dict{String,String})::Vector{String}
    code = remove_outer_parentheses(code)

    if ":=" in code
        equality_index = findfirst(==(":="),code)
        code = [code[1:equality_index]...,add_outer_parentheses(code[equality_index+1:end])...]
    end
    
    #handle multiple groups
    grouped_code = group_parentheses(code)
    codes = split_list_on_commas(grouped_code)
    if length(codes) > 1
        result = []
        for c in codes
            result = [result...,replace_definitions(ungroup_parentheses(c),definitions)...,","]
        end
        return result[1:end-1]
    end
    
    #handle individual groups, if reaches here only one group
    #check for match entire group with definition
    for key in keys(definitions)
        match_result = checkMatches(code,parse(key),true)
        if match_result[1]
            return replace_vars(parse(definitions[key]),match_result[2])
        end
    end

    #check each term in the current group for match with definition
    grouped_code = group_parentheses(code)
    for term_index in reverse(1:length(grouped_code))
        for key in keys(definitions)
            match_result = checkMatches(ungroup_parentheses([grouped_code[term_index]]),parse(key),true)
            if match_result[1]
                rv = add_outer_parentheses(replace_vars(parse(definitions[key]),match_result[2]))
                grouped_code = [grouped_code[1:term_index-1]...,group_parentheses(rv)...,grouped_code[term_index+1:end]...  ]
            elseif grouped_code[term_index][1] == '('  #handle term by term within group
                rv = replace_definitions(ungroup_parentheses([grouped_code[term_index]]),definitions)
                grouped_code = [grouped_code[1:term_index-1]...,group_parentheses(add_outer_parentheses(rv))...,grouped_code[term_index+1:end]...  ]
            end
        end
    end

    code = ungroup_parentheses(grouped_code)

    #Add order so definitions may contain terms from other definitions
    return code
end

function evaluate(code::Vector{String})

    grouped_code = group_parentheses(remove_outer_parentheses(code))
    if length(grouped_code) == 2 &&  occursin("->",grouped_code[1])
        arg =  evaluate(remove_outer_parentheses(ungroup_parentheses([grouped_code[2]])))
        return(modus_ponens(arg,remove_outer_parentheses(ungroup_parentheses([grouped_code[1]]))))
    end
    return code
end

function run(file_name::String)
    # Open the file
    file = open(file_name, "r")

    # Read the contents of the file
    contents = read(file, String)

    # Close the file
    close(file)

    # Print the contents of the file
    lines = split(contents,"\n")
    definitions = Dict{String,String}()

    #Remove comments and empty lines
    lines = [strip(line) for line in lines if strip(line) != "" && strip(line)[1] != '#']

    for line_index in eachindex(lines)
        line = lines[line_index]
        line = replace_definitions(parse(line),definitions)
        definitions = merge(definitions,assignment_to_match(line))

        println(join(evaluate(line),' '))
        lines[line_index] = join(line,' ')
    end



    #println("\n\n")
    #for line in lines
    #    println(line) 
    #end
    #println("\n\n")
    #println(definitions)
end

#include("test.jl")

run("script.hm")

#definitions = Dict{String,String}("a"=>"b c d")
#println("replace: ",replace_definitions(parse("c _x := a"),definitions))


#definitions = Dict{String,String}("_x is Num" =>"_x has size")
#println(replace_definitions(parse("a b c, (a is Num), q r s"),definitions))


#=
using HTTP

println("starting server")
# start a blocking server
HTTP.listen() do http::HTTP.Stream
    println("got request")
    @show http.message
    @show HTTP.header(http, "Content-Type")
    while !eof(http)
        println("body data: ", String(readavailable(http)))
    end
    HTTP.setstatus(http, 404)
    HTTP.setheader(http, "Foo-Header" => "bar")
    HTTP.startwrite(http)
    write(http, "response body")
    write(http, "more response body")
end
println("done")
=#




