#main file


#Convert code to symbol list including parentheses and bars
function parse(code::String)::Vector{String}
    code = replace(code,"("=>" ( ")
    code = replace(code,")"=>" ) ")
    code = replace(code, "|" => " | ")
    code = replace(code,r"\s+"=>" ")
    code = filter( (x) -> x != "", split(code," "))
    return code 
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
                    return ["("...,code...,")"...]
                end
            end
        end
        return code
    end
    return ["("...,code...,")"...]
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

    code1 = remove_outer_parentheses(code1)
    pattern = remove_outer_parentheses(pattern)

    example_index = 1
    #Compare each term one by one
    for pattern_index in 1:length(pattern)

        println(code1[example_index], " ", pattern[pattern_index])
        if example_index > length(code1) || (code1[example_index] != pattern[pattern_index] && pattern[pattern_index][1] != '_' && code1[end] != '_' && pattern[pattern_index][1] != '|')
            return get_vars ? (false,matches) : false
        end

        #if the string is (, skip to the the closing )
        if code1[example_index] == "(" && pattern[pattern_index] != "("
            paren_count = 1
            for i in example_index+1:length(code1)
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
        #Handle disjunctions
        elseif code1[example_index] != "|" && pattern[pattern_index] == "|"
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
        #Keep track of matching vars    
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

println(checkMatches(parse("Sam I (hate beards)"),parse("(Sam I _Fam)"),true))



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





