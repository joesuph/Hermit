#=

- Collect memory devices, visualizations, analogies
- Collect engaging aspects, perspectives, and great quotes
- Collect Concrete Examples and the step-by-step thought process for each
- Provide extra questions I thought of to explore the subject conceptually for 
- Collect Concrete examples of relationships, mechanisms, applications, problems and solution steps 
- Collect analogies, definitions, claims, Images (graphs, diagrams), Motivations for discovery, history of discovery, key facts

=#

Questions = Set()
Analogies = Set()
Claims = Set()
Defs = Set()
Motivations = Set()
Concrete_example = Set()

Cards = Dict()

function question(q)
    push!(Questions,q)
end

function def(d)
    push!(Defs,d)
end

function card(l,r)
    Cards[l] = r
end

function card(l,r,t)
    Cards[l] = [r,t]
end

function claim(c)
    push!(Claims,c)
end

function example(e)
    push!(Concrete_example,e)
end

push!(Questions,"If someone claims, a medicine helped there knee health, how do we know?")
push!(Questions,"How do we know that the medicine would work the same for someone else?")

card("what is reverse casuality?","Even if there is a causal relationship, sometimes the direction is unclear")

card("What is an example of reverse casuality?","Does green space cause more exercise or does exercise cause more green space?")

claim("How to clear up confusion? Formal definitions for causual effects, assumptions necessary to identify casual effects from data, rules about what variables need to be controoled for, senstivity analysis to determine the impact of viloations of assumptions on conclusonos")

question("How are causal diagrams related to potential outcomes?")

question("What is optimal dynamic treatement strategies?")

question("What is targeted learning?")

claim("Casual inference requires making some untestable assumptions")

claim("observational studies can only try to grasp the truth without providing absolutes")

claim("When we think about casual effects we think about the outcome results from a treatment")

def("treatment: aka exposure, the topic which causal inference tries to identify the outcome of")

def("We use a binary value for treatments where 1 is the treatment is present and 0 is where it is not present\
    we encode to numeric values so we can use them mathematically")

def("Potential outcome: The outcomes that we would see under each possible treatment option")

def("Yᵃ is the outcome would be observed if treatment A was set to a or the outcome when A=a (a is 0 or 1)")

example("Suppose the treatement is regional (A=1) versus general (A=0) anestheia for a hip fra\
    cture surgery. The outcome (Y) is major pulmonayr complications. 
    
    Y¹:equal to 1 if pulmonary complicatinos occured and equal to 0 otherwise, if given regional\
     anethesia
    
    Y⁰: equal to 1 if complications occured and equal to 0 otherwise if not given anesthisia
    
    ")

def("Counterfactual: Outcomes that would have occured if the treatment has been different. If treatment A=1 then\
    counterfactual is Y⁰")

example("Example of values:
    
    Did vaccine prevent me from getting the flu?
    
    What happened:
    ̇∘ I got the flu and didn't get sick
    ∘ My actual exposure was A=1
    ∘ My observed outcome was Y=Y¹
    
    What would have happened (contrary to fact):
    ∘ Had I not gotten the vaccine, would I have gotten sick?
    ∘ My counterfactual exposure is A=0
    ∘ My counterfactual outcome is Y⁰
    ")

def("Before a treatment decision is made, any outcome is considered a potential outcome")
claim("After the study there is an observed outcome and a counterfactual outcome")
claim("Counterfactual outcomes Y⁰,Y¹ are typically assumed to be the same as potential outcomes Y⁰, Y¹")

claim("Identifiability of causual effects require making some untestable assumptions")

claim("\
    The most common causal assumptions are: 
    ∘ Stable Unit Treatment Value Assumption (SUTVA),
    ∘ Consistency
    ∘ Ignorability
    ∘ positivity
    ")

def("
    SUTVA: 
    ∘ No interference 
        ∘ units don't interefere
        ∘Treatment assignment of one unit does not effect the outcome of another unit
        ∘ spillover or contagion are also terms for interference
    ∘ One version of treatment
        ∘ One variable that can intervened on that is well defined
    → SUTVA allows us to write the potential outcome for the ith person in terms of only that person's \
    treatments
    
    Consistency:
    ∘ The potential outcome under treatment A=a, Yᵃ, is equal to the observed outcome if the actual \
    treatement received is A=a
    ∘ In other words, Y=Yᵃ if A = a
    
    Ignorability:
    ∘ Given pretreatment covariates X, treatment assignment is independent from potential outcomes
    ∘ Among people with the same values of X, we can think of treatment A as being randomly assigned
    
    Positivity:
    ∘ For every set of values of X, treatment assignment was not deterministic
    ∘ P(A=a|X=x)>0 for a and x
    ")

example("Simple example of ignorability assumption: 
    ∘ X is a single variable (age) that can take values 'younger' or 'older'
    ∘ Older people are more likely to get treatment A=1
    ∘ Older people are also more likely to have the outcome (hip fracture) regardless of treatment
    Thus Y⁰,Y1 are not independent from A (marginally).
    However, Within Levels of X, treatment might be randomly assigned")

claim("If given a value of X, if everyone is treated then there is no hope in determining an effect")

claim("Assumptions can be put together to identify causal effects")

claim("We can observe E(Y|A=a,X=x) from data
    →E(Y|A=a,X=x)=E(Ya|A=a,X=x) by consistency
    →E(Ya|A=a,X=x)=E(Ya|X=x) by ignorability
    
    If we want a marginal causal effect we can average over X.
    ")

claim("If there is a single categorical X variable, Expected value marginalized of a treatment:
    E(Ya) = ∑ₓ E(Y|A=a,X=x)P(X=x)   \
")

def("Standardization: involves stratifying and then averaging.
    ∘ obtain a treatment effect within each starutmand then pool acroos stratup\
    weighing by the probability size of each stratum
    ∘From data you could estimate at treatment effect by computing means under \
    treatment within each stratum and pooling across stratum
    ")
example("
    Comparing two diabetes treatments drugA or drugB
    Outcome: Major Adverse Cardiac Event (MACE)
    Challenge:
    ∘drugA users were more likely to have had past use of some other oral antidiabetic drug
    ∘Patients with past use of OAD drugs are at higher risk for MACE in general
    
    Main idea:
    ∘ Computer rate of mace for drugA and drugB in two subpopulations
        ∘patients with prior OAD use
        ∘ patients without prior OAD use
    
    ∘Then Take weighted average, where weights are based on proportionf of people\
    in each subpopulation
    ∘This is a causal effect if within levels of prior OAD use variable, treatement can be
    thought of as randomized (in reality more variables would be needed)

    Data:
    drug | MACE=yes |MACE=no |total
    a    |350       | 3650   | 4000
    b    |500       |6500    |7000
    Total|750       |10250   |11000
    
    Probability of MACE given drugA = 350/4000=.088
    Probabilitty of MACE given drugB: 500/7000=0.71
    
    Stratify on X variable (prior OAD use)
    
    No Prior OAD use                     Prior OAD use
    drug | MACE=yes |MACE=no |total      drug | MACE=yes |MACE=no |total
    a    |50        | 950    | 1000      a    |300       | 2700   | 3000
    b    |200       |3800    |4000       b    |300       |2700    |3000
    Total|250       |4750    |5000       Total|650       |5400    |6000
   
    Prop of MAce given A: .05            Prob of MACE given A: 0.1
    Prob of MACE given B: .05            Prob of MACE given B: 0.1
    
    In either group treatment effect does not effect MACE
    
    ")

claim("We marginalize over all X levels so we can estimate treatment effect not \
    dependent on X")

claim("There are some problems with standardization:
    ∘ Typically, there will be many X variables needed to achive ignorability
    ∘ Stratification would lead to many empty sales
        ∘ To stratify age and blood pressure there will be many combination fo age\
        and blood pressure for which you have no data
    Thus an alternative to standardization is needed")

example("Cross-sectional look at treatments: We are interested in whether \
    yoga affects blood pressure. 
    
    At any given time some people regularly practice yoga while others do not. \
    ∘ Those who do not might have in the past
    ∘ Those that do might have been practicing for a long time or might be beginners
    ∘ Why did some people stop while others continued? What if those that quit did\
    so because it was not working for them? This is a type of selection bias that is\
    very difficult to control for

    ")

