@compile_workload begin 
    for t in ([1], tuple(1), (; key = 1), Set([1]), Dict(:key => 1) )
        repr_pretty(t)
    end
end