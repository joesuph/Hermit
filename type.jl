#main file



#Convert code to symbol list including parentheses and bars
function parse(code::String)::Vector{String}
    code = replace(code,"("=>" ( ")
    code = replace(code,")"=>" ) ")
    code = replace(code, "|" => " | ")
    code = replace(code,"["=>" [ ")
    code = replace(code,"]"=>" ] ")
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


function checkMatches(code1::Vector{String},pattern::Vector{String}, get_vars = false)
    matches = Dict()

    #remove outer parenthesis
    pattern = remove_outer_parentheses(pattern)
    pattern_is_just_disjunction = check_outer_square_brackets(pattern)
    if pattern_is_just_disjunction
        code1 = add_outer_parentheses(code1)
    else
        code1 = remove_outer_parentheses(code1)
    end

    println(code1)
    println(pattern)

    example_index = 1
    pattern_index = 1
    #Compare each term one by one
    while pattern_index <= length(pattern)
        #Compare code term and pattern term
        println(code1[example_index], " ", pattern[pattern_index])
        #if they don't match or have a speccial case return false
        if example_index > length(code1) || #pattern is longer than code
                (code1[example_index] != pattern[pattern_index] && #code doesn't match pattern
                pattern[pattern_index][1] != '_' && #pattern is not wildcard
                code1[end] != '_' &&      #code is not existential
                pattern[pattern_index][1] != '[')  #pattern is not disjunction

            return get_vars ? (false,matches) : false
        end

        #if the string is (, skip to the the closing )
        if code1[example_index] == "(" && pattern[pattern_index] == "_"
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
                        println("new_index: ",example_index)
                        break
                    end
                end
            end
            
            
            println("arg: ",arg)
            @assert arg != "" #if empty argument wasn't read correctly

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
            #=Old section

            option_list = split(pattern[pattern_index],'|')[2:end-1]
            for i in 1:length(option_list)
                if code1[i] == "("
                    paren_count += 1
                elseif code1[i] == ")"
                    paren_count -= 1
                    if paren_count == 0
                        
                        if haskey(matches,pattern[pattern_index])
                            if matches[pattern[pattern_index]] != join(code1[example_index:i], ' ')
                                return get_vars ? (false,matches) : false
                            end
                        else
                            matches[pattern[pattern_index]] = join(code1[example_index:i], ' ')
                        end

                        example_index = i
                        break
                    end
                end
            end
            =#
        #Handle Lambdas

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

    return get_vars ? (true,matches) : true
end



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
    println(grouped_implication)
    @assert grouped_implication[2] == "->"

    premise = parse(grouped_implication[1])

    match_result = checkMatches(code,premise,true)

    @assert match_result[1] == true

    conclusion = remove_outer_parentheses(parse(grouped_implication[3]))

    conclusion = replace_vars(conclusion,match_result[2])

    return conclusion
end


code = "_a -> (_b -> (_a -> _a = _b)), (Sam tam)"
code=  "(Sam tam)"

code2 = parse(code)

println(checkMatches(parse("b > 2"),parse("[_x is Num|_x > 2]"),true))

#Do I need to remove outer parentheses?
#how does it make it helpful? 
#Maybe if I ensure outer parenthesis, then I add skip if we do

# Read string from file
#filename = "script.hm"
#fcode = read(filename, String)

#fcode = split(fcode,"\n")

#code2 = group_parentheses(file_contents)


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





