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

function parse_node_file(inpath)
	nodedata = CSV.read(IOBuffer(replace(read(inpath), UInt8('\t') => UInt8(' '))), DataFrame; select=1:3, delim=' ', ignorerepeated=true);
	rename!(nodedata, [:id, :x, :y])
	return nodedata
end

function parse_trips_file(inpath)
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
				for m in eachmatch(r"(\d+)\s*:\s*(\d+\.?\d*) ?;", line)
					trips[i, parse(Int, m.captures[1])] = parse(Float64, m.captures[2])
				end
			end
		end
		nzones, trips
	end

	tripdata = DataFrame([(src = i, dst = j, volume = trips[i,j]) for i in 1:nzones, j in 1:nzones if trips[i,j] > 0.0])

	# CSV.write(outpath, tripdata; delim="\t")
	# tripdata = nothing
	# return
	return tripdata
end

function parse_net_file(inpath)
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

	linkdata = CSV.read(inpath, DataFrame; header=headerrow, drop=["~", ";"])
	return nnodes, nzones, ftnode, linkdata
end

function parse_flow_file(inpath)
	flowdata = CSV.read(inpath, DataFrame)
	rename!(flowdata, [:src, :dst, :volume, :cost])
	return flowdata
end

function parse_tntp_data(outpath; net_file_path, node_file_path, trips_file_path, flow_file_path)
	if !isdir(outpath)
		mkdir(outpath)
	end

	nnodes, nzones, ftnode, linkdata = parse_net_file(net_file_path)
	nodedata = !isnothing(node_file_path) ? parse_node_file(node_file_path) : DataFrame(:id => 1:nnodes)
	nodedata.is_zone = (1:nnodes) .≤ nzones
	nodedata.through_flow_allowed = (ftnode == 1) ? fill(true, nnodes) : nodedata.is_zone
	tripdata = parse_trips_file(trips_file_path)
	flowdata = isnothing(flow_file_path) ? nothing : parse_flow_file(flow_file_path)

	for (fname, data) in zip(["links.csv", "nodes.csv", "trips.csv", "best_flows.csv"], [linkdata, nodedata, tripdata, flowdata])
		!isnothing(data) && CSV.write(joinpath(outpath, fname), data)
	end

	nodedata = nothing
	linkdata = nothing
	tripdata = nothing
	flowdata = nothing
end

function _find_first_element(cond_func, v)
	i = findfirst(cond_func, v)
	return isnothing(i) ? nothing : v[i]
end