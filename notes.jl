seq = []
tags = Dict()
id = 0



function add(tag::String,note)
    global tags
    global id
    global seq 
    id += 1
    push!(seq, [id,tag,note])
    if haskey(tags,tag)
        push!(tags[tag], [id,note])
    else
        tags[tag] = [[id,note]]
    end
end

function add_n(tag_list::Vector{String},note)
    for tag in tag_list
        add(tag,note)
    end
end

function claim(note::String)
    add("claim",note)'
end

function question(note::String)
    add("question",note)
end

function vocab(note::String)
    add("vocab",note)
end

#How can I organize this into notes?
function summary(note::String)
    add("summary",note)
end

function example(note::String)
    add("example",note)
end

function hermit(note::String)
    add("hermit",note)
end


macro note_tag(tag,note)
    quote
        add($tag,$note)
    end
end


macro n(note)
    quote
        add("note",$note)
    end
end

macro n(tag_list,note)
    quote
        add_n($tag_list,$note)
    end
end

macro h1(note)
    quote
        add("h1",$note)
    end
end

macro h2(note)
    quote
        add("h2",$note)
    end
end

macro h3(note)
    quote
        add("h3",$note)
    end
end

macro sum(note)
    quote
        add("summary",$note)
    end
end

macro ex(note)
    quote
        add("example",$note)
    end
end

macro claim(note)
    quote
        add("claim",$note)
    end
end

macro q(note)
    quote
        add("question",$note)
    end
end

macro hm(note)
    quote
        add("hermit",$note)
    end
end

macro defin(note)
    quote
        add("definition",$note)
    end
end

macro a(note)
    quote
        add("answer",$note)
    end
end

@h1 "Introduction"

    @q "What is the point of category Theory?"

    @claim "Category theory is language to describe different structures in a uniform way."

    @hm "Cat_def :=  isCategory _A _B <-->  _A::objects, _B::morphismsOn[A], _C::compOn[_B], _I::idOn[_A], (_A _B) sats (Typing Axioms)"
    
    @hm " _f : _A -> _B <--> _f in morphisms, _A::domain, _B::codomain"

    @hm " _f : _A -> _B, _g : _B -> _C --> _g o _f : _A -> _C"

    @hm "ax1.3 := f : a -> b, f : d -> e --> a = d, b = e"
    @hm "ax1.4 := f : a -> b, g : b -> c --> g o f : a -> c"
    @hm "ax1.5 := id_[a] : a -> a"


    @hm "f:morphism, f : a -> b --> f : wellTyped"
    @claim "It is convention that all terms are assumed to be well typed before we talk about them so all terms mentioned can be assumed to be well typed"

    @hm "(f ∘ g) ∘ h == f ∘ (g ∘ h)"
    @hm "f ∘ id_[a] == f"
    @hm "id_[a] ∘ f == f"
    
    @hm " isPreCategory _A _B <-->  _A::objects, _B::morphismsOn[A], _C::compOn[_B], _I::idOn[_A]"

    @claim "Every pre-category can be used to make a category"
    @hm "IsPreCategory a b --> IsCategory a c_
        function precat_to_cat_thm 
            objects := [x for x in a]
            morphisms := [ [ (p[0], f, p[1]) for p in sig(f)] for f in b]
            f ∈ morphisms, g ∈ morphisms, cod(f) = dom(g) --> f ∘ g
            function comp
                λ x. f(g(x))
            end
            type-uniqueness 
            f ∈ morphisms, f: a -> b, f : c -> d --> a = c, b = d
            function 
                trans(a = f[0], c = f[0])
            end

            Cat_def(objects, morphisms, comp, id)
        end
    " 

    @defin "subcategory : A subcategory of another category is a category where all of it's morphisms and objects are also in the larger category"

    @defin "full subcategory : A full subcategory of a category is a subcategory where it contains all morphisms from the larger category between objects in the subcategory"

    @defin "built upon : A category is built upon another category C if it's moprhisms are moprhisms are in C and compsition and identities are inherited from C, and it's objects are collections of morphisms in C, and it's typing f: A->B is defined as collections of equations between the morphisms f, A, B, in A."

    @ex "built upon : the category Alg(I) is built upon the category of set. Objects in Alg(I) are binary operations and morphisms are homomorphisms." 

    @h2 "Functors"

        @defin "Functor : A functor is a mapping from one category to another that preserves the categorical structure, that is, it preservese the property of being an object, the property of being a morphism, the typing, the composition, and identities.
        A functor from category A to cateogry B is a mapping F that sends objects of A to objects of B and morphisms of A to morphisms of B such that
        F(f : a -> b) = F(f) : F(a) -> F(b) 
        F(g ∘ f) = F(g) ∘ F(f)
        F(id_[a]) = id_[F(a)]
        "
        
        @hm "def f IsFunctor := "

        @defin "endofunctor : A functor from a category to itself"

        @ex "functor : 
        Ⅱ A = A × A
        Ⅱ f = (a,a') -> (fa, fa') : Ⅱ A -> Ⅱ B
        This twin or bin functor, Ⅱ, takes a function or object and creates a function that applies to pairs or creates a pair of objects from an object.
        Ⅱ nat is all pairs of natural numbers 
        and Ⅱ succ maps (19,48) to (20,49). 
        "

        @ex  "functor : 
        Seq is a functor of type Set -> Set
        Seq A = the set of finite sequences over A
        Seq f = [a0, ..., a_n-1] -> [f(a0), ..., f(a_n-1)]
        
        Seq succ maps [1,2,3] to [2,3,4]
        "

        @claim "In the definition of a category, objects are “just things”
        for which no internal structure is observable by categorical means (composition, identities,
        morphisms, and typing). Functors form the tool to deal with “structured” objects. Indeed,
        in Set an (the?) aspect of a structure is that it has “constituents”, and that it is possible
        to apply a function to all the individual constituents; this is done by Ff: FA → FB .
        So I is or represents the structure of pairs; I A is the set of pairs of A , and I f is
        the functions that applies f to each constituent of a pair. Also, Seq is or represents
        the structure of sequences; Seq A is the structure of sequences over A , and Seq f is the
        function that applies f to each constituent of a sequence.
        "

        @claim " for Functor 
        
        +: I A -> A
        x: I B -> B
        f : A -> B
        f : + -> x means +,f = I f, x        
        
        
        "
        


