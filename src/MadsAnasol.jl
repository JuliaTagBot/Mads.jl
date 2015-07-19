using Anasol

@doc "Compute concentration for a point (x,y,z,t)" ->
function contamination(wellx, welly, wellz, n, lambda, theta, vx, vy, vz, ax, ay, az, x, y, z, dx, dy, dz, f, t0, t1, t)
	d = -theta * pi / 180
	xshift = wellx - x
	yshift = welly - y
	ztrans = wellz - z
	xtrans = xshift * cos(d) - yshift * sin(d)
	ytrans = xshift * sin(d) + yshift * cos(d)
	x01 = x02 = x03 = 0. # we transformed the coordinates so the source starts at the origin
	sigma01 = sigma02 = sigma03 = 0.#point source
	#=
	sigma01 = dx
	sigma02 = dy
	sigma03 = dz
	=#
	v1 = vx
	v2 = vy
	v3 = vz
	speed = sqrt(vx * vx + vy * vy + vz * vz)
	sigma1 = sqrt(ax * speed * 2)
	sigma2 = sqrt(ay * speed * 2)
	sigma3 = sqrt(az * speed * 2)
	H1 = H2 = H3 = 0. # these parameters will be ignored
	xb1 = xb2 = xb3 = 0. # xb1 and xb2 will be ignored, xb3 should be set to 0 (reflecting boundary at z=0)
	return 1e6 * f * Anasol.long_bbb_ddd_iir_c([xtrans, ytrans, ztrans], t, x01, sigma01, v1, sigma1, H1, xb1, x02, sigma02, v2, sigma2, H2, xb2, x03, sigma03, v3, sigma3, H3, xb3, lambda, t0, t1) / n
end

@doc "Compute concentration for all observation points" ->
function computeconcentrations(parameters, madsdata) # TODO decide how to access madsdata ...
	x = parameters["x"]
	y = parameters["y"]
	z = parameters["z"]
	dx = parameters["dx"]
	dy = parameters["dy"]
	dz = parameters["dz"]
	f = parameters["f"]
	t0 = parameters["t0"]
	t1 = parameters["t1"]
	n = parameters["n"]
	lambda = parameters["lambda"]
	theta = parameters["theta"]
	vx = parameters["vx"]
	vy = parameters["vy"]
	vz = parameters["vz"]
	ax = parameters["ax"]
	ay = parameters["ay"]
	az = parameters["az"]
	results = OrderedDict()
	for wellkey in Mads.getwellkeys(madsdata)
		wellx = madsdata["Wells"][wellkey]["x"]
		welly = madsdata["Wells"][wellkey]["y"]
		wellz0 = madsdata["Wells"][wellkey]["z0"]
		wellz1 = madsdata["Wells"][wellkey]["z1"]
		n = length(madsdata["Wells"][wellkey]["obs"])
		c = OrderedDict()
		for i in 1:length(madsdata["Wells"][wellkey]["obs"])
			t = madsdata["Wells"][wellkey]["obs"][i][i]["t"]
			c[t] = .5 * (contamination(wellx, welly, wellz0, n, lambda, theta, vx, vy, vz, ax, ay, az, x, y, z, dx, dy, dz, f, t0, t1, t) + contamination(wellx, welly, wellz1, n, lambda, theta, vx, vy, vz, ax, ay, az, x, y, z, dx, dy, dz, f, t0, t1, t))
			# c[t] = contamination(wellx, welly, .5 * (wellz0 + wellz1), n, lambda, theta, vx, vy, vz, ax, ay, az, x, y, z, dx, dy, dz, f, t0, t1, t)
		end
		results[wellkey] = c
	end
	return results
end
