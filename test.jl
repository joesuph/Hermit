using Test

@testset "Base" begin
    @test parse("a b c") == ["a","b","c"]
    @test parse("a (b c)") == ["a","(","b","c",")"]
    @test checkMatches(parse("a b c"),parse("a b c")) == true
    @test checkMatches(parse("a b c"),parse("a b d")) == false
    @test checkMatches(parse("a b c"),parse("a _d _f")) == true
    @test checkMatches(parse("a b c"),parse("a _d _d")) == false
    @test checkMatches(parse("a b c"),parse("a _d _d"),true) == (false,Dict{String,String}("_d" => "b"))
    @test checkMatches(parse("a b c"),parse("a _d _f"),true) == (true,Dict{String,String}("_d"=>"b","_f"=>"c"))
    @test checkMatches(parse("a b c"),parse("[_x is Num|_c b c]")) == true
    @test checkMatches(parse("a b c"),parse("[_x is Num|_c b c]"),true) == (true,Dict{String,String}("_c"=>"a"))
    @test checkMatches(parse("a (sam is cool) c"),parse("a _d c")) == true
    @test begin
        nat = "0 is Num, (_x is Num) -> ((succ _x) is Num, succ _x)"
        nat = parse(nat)
        nat = group_parentheses(nat)
        nat = split_list_on_commas(nat)

        one = proj(modus_ponens(nat[1],ungroup_parentheses(nat[2])),1)
        join(proj(modus_ponens(one,ungroup_parentheses(nat[2])),1)," ") == "( succ ( succ 0 ) ) is Num"
    end
    @test begin 
        a = "one is Num"
        b = "_a is Num -> (succ _a) is Num"
        modus_ponens(parse(a),parse(b)) == parse("(succ one) is Num")
    end
    @test begin
        definitions = Dict{String,String}()
        definitions = merge(definitions,assignment_to_match(parse("a _d := b c _d")))
        replace_definitions(parse("a sam"),definitions) == ["b","c","sam"]
    end
    @test split_list_on_commas(parse("a b, cam")) == [["a","b"],["cam"]]
end

