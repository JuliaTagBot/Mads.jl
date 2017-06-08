import DataStructures

i = open("parameters.dat", "r")
param = readdlm(i)
close(i)
a = param[1]
b = param[2]
f(t) = a * t - b # a * t - b
times = 0:4
predictions = DataStructures.OrderedDict{String, Float64}(zip(map(i -> string("o", i), times), map(f, times)))
writedlm("observations.dat", predictions)