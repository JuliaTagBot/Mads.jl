import Mads
using Gadfly
using JSON
using DataStructures
using ProgressMeter

# reload("Mads.jl")
# Example: reload("Mads.jl"); Mads.setmadsinputfile("w01short.mads"); reload("w01.jl")
Mads.madswarn("""Mads execution example: reload("Mads.jl"); Mads.setmadsinputfile("w01short.mads"); reload("w01.jl")""")

# load MADS problem
madsdirname = string((dirname(Base.source_path())))
Mads.madsinfo("""Mads working directory: $(madsdirname)""")
madsfilename = Mads.getmadsinputfile()
if madsfilename == ""
	madsfilename = "w01short.mads"
	Mads.madswarn("""Mads input file is empty; default value $(madsfilename) will be used""")
end
madsfilenamelong = madsdirname * "/" * madsfilename
md = Dict()
try
	md = Mads.loadyamlmadsfile(madsfilenamelong)
catch
	Mads.madswarn("""Mads input file: $(madsfilenamelong) is missing! Try in the local directory ...""")
	try
		madsfilenamelong = madsfilename
		md = Mads.loadyamlmadsfile(madsfilenamelong)
	catch
		Mads.madserr("""Mads input file: $(madsfilename) is missing; quit!""")
		error("$(madsfilename) is missing")
	end
end

Mads.madsinfo("""Mads Input file: $(madsfilenamelong)""")

# get MADS rootname
rootname = Mads.madsrootname(md)
Mads.madsinfo("""Mads root name: $(rootname)""")

# get all the parameters
paramkeys = Mads.getparamkeys(md)

# get the parameters that will be analyzed
optparamkeys = Mads.getoptparamkeys(md)

# get all the parameter initial values
paramdict = OrderedDict(zip(paramkeys, map(key->md["Parameters"][key]["init"], paramkeys)))

# create a function to compute concentrations
computeconcentrations = Mads.makecomputeconcentrations(md)

# compute concentrataions based on the initial values
forward_preds = computeconcentrations(paramdict)

# solve the inverse problem
# result = Mads.calibrate(md; show_trace=true)

# perform global SA analysis (saltelli)
saltelliresultm = Mads.saltelli(md,N=int(500))
Mads.plotwellSAresults("w1a",md,saltelliresultm)
saltelliresultb = Mads.saltellibrute(md,N=int(500))
Mads.plotwellSAresults("w1a",md,saltelliresultb)

# save saltelli results
# f = open("$rootname-SA-results.json", "w")
# JSON.print(f, saltelliresult)
# close(f)

# load saltielli results
# saltelliresult = JSON.parsefile("$rootname-SA-results.json"; ordered=true, use_mmap=true)

# print saltieli results
# Mads.saltelliprintresults(md, result)

# plot global SA results for a given observation point
# Mads.plotwellSAresults("w1a",md,result)

Mads.madsinfo("Manual SA ...")
numberofsamples = 10
paramvalues=Mads.parametersample(md,numberofsamples)
for paramkey in keys(paramvalues)
	t = Array(Float64,length(md["Observations"]))
	Y = Array(Float64,length(md["Observations"]),numberofsamples)
	@showprogress 1 "Computing ..." for i in 1:numberofsamples
		original = paramdict[paramkey]
		paramdict[paramkey] = paramvalues[paramkey][i]
		forward_preds = computeconcentrations(paramdict)
		j = 1
		for obskey in keys(forward_preds)
			Y[j,i] = forward_preds[obskey]
			j += 1
		end
		paramdict[paramkey] = original
	end
	p=Gadfly.plot([layer(x=1:50, y=Y[:,i], Geom.line,
                 Theme(default_color=color(["red" "blue" "green" "cyan" "magenta" "yellow"][i%6+1])))
								 for i in 1:numberofsamples]...)
	Gadfly.draw(SVG(string("$rootname-MSA-$paramkey-$numberofsamples.svg"),6inch,4inch),p)
end

# parameter space exploration
# Mads.madsinfo("Parameter space exploration ...")
# numberofsamples = 100
# paramvalues=Mads.parametersample(md, numberofsamples)
# Y = Array(Float64,length(md["Observations"]),numberofsamples * length(paramvalues))
# k = 0
# for paramkey in keys(paramvalues)
#   for i in 1:numberofsamples
#     original = paramdict[paramkey]
#     paramdict[paramkey] = paramvalues[paramkey][i] # set the value for each parameter
# 		forward_preds = computeconcentrations(paramdict)
#     paramdict[paramkey] = original
# 		j = 1
# 		for obskey in keys(forward_preds)
# 			Y[j,i + k] = forward_preds[obskey]
# 			j += 1
# 		end
#   end
# 	k += numberofsamples
# end
# save model inputs (not recommended)
# writedlm("$rootname-input.dat", paramvalues)

# save model inputs
# f = open("$rootname-input.json", "w")
# JSON.print(f, paramvalues)
# close(f)

# load saltielli results
# paramvalues = JSON.parsefile("$rootname-input.json"; ordered=true, use_mmap=true)

# save model outputs
# writedlm("$rootname-output.dat", Y)
