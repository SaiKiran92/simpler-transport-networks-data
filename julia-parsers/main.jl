import Pkg; Pkg.activate(Base.source_dir())

using Revise
using CSV, DataFrames

includet("parser-functions.jl")

INPUT_DIR = "/home/saikiran/Documents/TransportationNetworks-master/"
OUTPUT_DIR = "/home/saikiran/Documents/simpler-transport-networks-data/"

file_name_dict = Dict(
	"Anaheim" => ["Anaheim_net.tntp", nothing, "Anaheim_trips.tntp", "Anaheim_flow.tntp"],
	"Austin" => ["Austin_net.tntp", nothing, "Austin_trips_am.tntp", nothing],
	"Barcelona" => ["Barcelona_net.tntp", nothing, "Barcelona_trips.tntp", "Barcelona_flow.tntp"],
	"Berlin-Center" => ["berlin-center_net.tntp", "berlin-center_node.tntp", "berlin-center_trips.tntp", nothing],
	"Berlin-Friedrichshain" => ["friedrichshain-center_net.tntp", "friedrichshain-center_node.tntp", "friedrichshain-center_trips.tntp", nothing],
	"Berlin-Mitte-Center" => ["berlin-mitte-center_net.tntp", "berlin-mitte-center_node.tntp", "berlin-mitte-center_trips.tntp", nothing],
	"Berlin-Mitte-Prenzlauerberg-Friedrichshain-Center" => ["berlin-mitte-prenzlauerberg-friedrichshain-center_net.tntp", "berlin-mitte-prenzlauerberg-friedrichshain-center_node.tntp", "berlin-mitte-prenzlauerberg-friedrichshain-center_trips.tntp", nothing],
	"Berlin-Prenzlauerberg-Center" => ["berlin-prenzlauerberg-center_net.tntp", "berlin-prenzlauerberg-center_node.tntp", "berlin-prenzlauerberg-center_trips.tntp", nothing],
	"Berlin-Tiergarten" => ["berlin-tiergarten_net.tntp", "berlin-tiergarten_node.tntp", "berlin-tiergarten_trips.tntp", nothing],
	"Birmingham-England" => ["Birmingham_Net.tntp", "Birmingham_Nodes.tntp", "Birmingham_Trips.tntp", nothing],
	"Braess-Example" => ["Braess_net.tntp", nothing, "Braess_trips.tntp", nothing],
	"Chicago-Sketch" => ["ChicagoSketch_net.tntp", "ChicagoSketch_node.tntp", "ChicagoSketch_trips.tntp", "ChicagoSketch_flow.tntp"],
	"Eastern-Massachusetts" => ["EMA_net.tntp", nothing, "EMA_trips.tntp", nothing],
	"GoldCoast" => ["Goldcoast_network_2016_01.tntp", "Goldcoast_nodes_2016_01.tntp", "Goldcoast_trips_2016_01.tntp", nothing],
	"Hessen-Asymmetric" => ["Hessen-Asym_net.tntp", nothing, "Hessen-Asym_trips.tntp", nothing],
	"Philadelphia" => ["Philadelphia_net.tntp", "Philadelphia_node.tntp", "Philadelphia_trips.tntp", nothing], # there's also a toll.tntp file in this; also, add header to the node file
	"SiouxFalls" => ["SiouxFalls_net.tntp", "SiouxFalls_node.tntp", "SiouxFalls_trips.tntp", "SiouxFalls_flow.tntp"],
	"Sydney" => ["Sydney_net.tntp", "Sydney_node.tntp", "Sydney_trips.tntp", nothing], # unzip trips file
	# "SymmetricaTestCase" => []
	"Terrassa-Asymmetric" => ["Terrassa-Asym_net.tntp", nothing, "Terrassa-Asym_trips.tntp", nothing],
	"Winnipeg-Asymmetric" => ["Winnipeg-Asym_net.tntp", nothing, "Winnipeg-Asym_trips.tntp", nothing],
	"Winnipeg" => ["Winnipeg_net.tntp", nothing, "Winnipeg_trips.tntp", "Winnipeg_flow.tntp"],
	"chicago-regional" => ["ChicagoRegional_net.tntp", "ChicagoRegional_node.tntp", "ChicagoRegional_trips.tntp", nothing]#"ChicagoRegional_flow.tntp"] # trip file - different
)

for (k,v) in pairs(file_name_dict)
	(k == "Terrassa-Asymmetric") && continue

	try
		parse_tntp_data(
			joinpath(OUTPUT_DIR, k);
			net_file_path = joinpath(INPUT_DIR, k, v[1]),
			node_file_path = isnothing(v[2]) ? nothing : joinpath(INPUT_DIR, k, v[2]),
			trips_file_path = joinpath(INPUT_DIR, k, v[3]),
			flow_file_path = isnothing(v[4]) ? nothing : joinpath(INPUT_DIR, k, v[4])
		)
	catch
		println("$k error")
	end
end


for folder_name in readdir(INPUT_DIR)
	!isdir(joinpath(INPUT_DIR, folder_name)) && continue
	if folder_name == "Terrassa-Asymmetric"
		println(folder_name, " some issue")
		continue
	end

	try
		parse_tntp_data(joinpath(INPUT_DIR, folder_name), joinpath(OUTPUT_DIR, folder_name))
		# println("done")
	catch
		println("$folder_name error")
	end
end

for folder_name in readdir(INPUT_DIR)
	!isdir(joinpath(INPUT_DIR, folder_name)) && continue
	if folder_name == "Terrassa-Asymmetric"
		println(folder_name, " some issue")
		continue
	end
	print(folder_name, " ")

	in_folder_path = joinpath(INPUT_DIR, folder_name)
	contents = readdir(in_folder_path)
	file_name = begin
		# x = findfirst(s -> endswith(s, "_node.tntp"), contents)
		x = findfirst(s -> endswith(s, "_trips.tntp"), contents)
		# x = findfirst(s -> endswith(s, "_net.tntp"), contents)
		# x = findfirst(s -> endswith(s, "_flow.tntp"), contents)
		if isnothing(x)
			println("file not found")
			continue
		else
			contents[x]
		end
	end

	out_folder_path = joinpath(OUTPUT_DIR, folder_name)
	if !isdir(out_folder_path)
		mkdir(out_folder_path)
	end

	try
		# parse_net_file(joinpath(in_folder_path, file_name), joinpath(out_folder_path, "links.csv"))
		parse_trips_file(joinpath(in_folder_path, file_name), joinpath(out_folder_path, "demands.csv"))
		# parse_node_file(joinpath(in_folder_path, file_name), joinpath(out_folder_path, "nodes.csv"))
		# parse_flow_file(joinpath(in_folder_path, file_name), joinpath(out_folder_path, "best_flows.csv"))
		println("done")
	catch
		println("parsing error")
	end
end
