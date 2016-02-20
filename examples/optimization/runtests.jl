import Mads
import Base.Test

workdir = Mads.getmadsdir() # get the directory where the problem is executed
if workdir == ""
	workdir = Mads.madsdir * "/../examples/optimization/"
end

info("External optimization ...")

md = Mads.loadmadsfile(workdir * "external-jld.mads")
jparam, jresults = Mads.calibrate(md, maxIter=1, maxJacobians=1)
md = Mads.loadmadsfile(workdir * "external-yaml.mads")
yparam, yresults = Mads.calibrate(md, maxIter=1, maxJacobians=1)

@test yparam == jparam

include(workdir * "optimization-lm.jl")
include(workdir * "optimization_rosenbrock.jl")
include(workdir * "optimization_callback.jl")
include(workdir * "optimization_linear_problem.jl")
include(workdir * "optimization_linear_problem+template.jl")