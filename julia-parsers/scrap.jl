
function parse_tntp_data(inpath, outpath)
	contents = readdir(inpath)
	node_file_name = _find_first_element(s -> endswith(s, "_node.tntp"), contents)
	flow_file_name = _find_first_element(s -> endswith(s, "_flow.tntp"), contents)
	net_file_name = _find_first_element(s -> endswith(s, "_net.tntp"), contents)
	trips_file_name = _find_first_element(s -> endswith(s, "_trips.tntp"), contents)

	if !isdir(outpath)
		mkdir(outpath)
	end

	nnodes, nzones, ftnode, linkdata = parse_net_file(joinpath(inpath, net_file_name))

	tripdata = parse_trips_file(joinpath(inpath, trips_file_name))

	nodedata = isnothing(node_file_name) ? DataFrame(:id => 1:nnodes) : parse_node_file(joinpath(inpath, node_file_name))
	# nodedata = DataFrame(:id => 1:nnodes)
	nodedata.is_zone = (1:nnodes) .≤ nzones
	nodedata.through_flow_allowed = (ftnode == 1) ? fill(true, nnodes) : nodedata.is_zone

	flowdata = isnothing(flow_file_name) ? nothing : parse_flow_file(joinpath(inpath, flow_file_name))

	for (fname, data) in zip(["links.csv", "nodes.csv", "trips.csv", "best_flows.csv"], [linkdata, nodedata, tripdata, flowdata])
		!isnothing(data) && CSV.write(joinpath(outpath, fname), data)
	end

	nodedata = nothing
	linkdata = nothing
	tripdata = nothing
	flowdata = nothing
end
