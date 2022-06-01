# helpers
read_meta_data(s::String) = read_meta_data(open(s, "r"))
function read_meta_data(io::IO)
	rv = Dict{String,String}()
	while (line = strip(readline(io))) != "<END OF METADATA>" # until we reach the end tag
		m = match(r"<(.*)>\s*(\d+.?\d*)", line)
		if !isnothing(m)
			rv[m.captures[1]] = m.captures[2]
		end
	end
	return rv
end

function parse_node_file(inpath, outpath)
	nodedata = CSV.read(IOBuffer(replace(read(inpath), UInt8('\t') => UInt8(' '))), DataFrame; select=1:3, delim=' ');
	rename!(nodedata, [:id, :x, :y])
	CSV.write(outpath, nodedata; delim="\t")
	nodedata = nothing
	return
end

function parse_trips_file(inpath, outpath)
	nzones, trips = open(inpath) do io
		md = read_meta_data(io)
		nzones, tflow = parse(Int, md["NUMBER OF ZONES"]), parse(Float64, md["TOTAL OD FLOW"])
		
		# read trip data
		trips = zeros(Float64, nzones, nzones)
		i = 0
		while !eof(io)
			line = strip(readline(io))
			m = match(r"Origin\s+(\d+)*", line)
			if !isnothing(m)
				i = parse(Int, first(m.captures))
			else
				for m in eachmatch(r"(\d+)\s*:\s*(\d+\.\d*);", line)
					trips[i, parse(Int, m.captures[1])] = parse(Float64, m.captures[2])
				end
			end
		end
		nzones, trips
	end

	tripdata = DataFrame([(src = i, dst = j, volume = trips[i,j]) for i in 1:nzones, j in 1:nzones if trips[i,j] > 0.0])

	CSV.write(outpath, tripdata; delim="\t")
	tripdata = nothing
	return
end

function parse_net_file(inpath, outpath)
	md = read_meta_data(inpath)
	nzones = parse(Int, md["NUMBER OF ZONES"])
	nnodes = parse(Int, md["NUMBER OF NODES"])
	ftnode = parse(Int, md["FIRST THRU NODE"])
	nlinks = parse(Int, md["NUMBER OF LINKS"])

	headerrow = open(inpath) do io
		headerrow = 0
		while (headerrow += 1; isnothing(match(r"^\s*~.*;\s*$", readline(io)))) # looking for a row that begins with ~ and ends with ;
			if eof(io) # End-Of-File check
				throw(InputError("Invalid network file."))
			end
		end
		return headerrow
	end

	links = CSV.read(inpath, DataFrame; header=headerrow, drop=["~", ";"])
	links.is_zone = (1:nlinks) .≤ nzones
	links.through_flow_allowed = (ftnode == 1) ? fill(true, nlinks) : links.is_zone

	CSV.write(outpath, links; delim="\t")

	links = nothing
	return
end

function parse_flow_file(inpath, outpath)
	flow_data = CSV.read(inpath, DataFrame)
	rename!(flow_data, [:src, :dst, :volume, :cost])
	CSV.write(outpath, flow_data; delim="\t")
	flow_data = nothing
	return
end