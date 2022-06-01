import Pkg; Pkg.activate(Base.source_dir())

using Revise
using CSV, DataFrames

includet("parser-functions.jl")

INPUT_DIR = "/home/saikiran/Documents/TransportationNetworks-master/"
OUTPUT_DIR = "/home/saikiran/Dropbox/work/github/simpler-transport-networks-data/"

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
