local mp = require("mp")
local utils = require("mp.utils")
local input = require("mp.input")

local out_dir = mp.command_native({ "expand-path", "~/clips" })

local start_time, end_time
local nabber_enabled = false

local function nab()
	if not start_time or not end_time then
		mp.osd_message("set start and end points first", 3)
		return
	end

	if start_time > end_time then
		mp.osd_message("girl how u tryna clip backwards", 3)
		return
	end

	mp.command_native({ name = "subprocess", args = { "mkdir", "-p", out_dir } })
	local file = mp.get_property("path")
	local duration = end_time - start_time
	local _, name = utils.split_path(file)

	input.get({
		prompt = "clip name:",
		submit = function(input_name)
			input.terminate()
			local out_name = (input_name and input_name ~= "") and input_name
				or (name:match("(.+)%..+") .. start_time .. "-" .. end_time)
			local out_path = utils.join_path(out_dir, out_name .. ".mp4")

			mp.command_native_async({
				name = "subprocess",
				args = {
					"ffmpeg",
					"-y",
					"-ss",
					tostring(start_time),
					"-i",
					file,
					"-t",
					tostring(duration),
					"-c:v",
					"libx264",
					"-ac",
					"2",
					"-vf",
					"format=yuv420p",
					out_path,
				},
				capture_stdout = true,
				capture_stderr = true,
			}, function(_, result, _)
				if result.status == 0 then
					mp.osd_message("nabbed: " .. out_path, 3)
				else
					mp.osd_message("oops", 3)
				end
			end)
		end
	})
end

local function toggle_nabber()
	if not nabber_enabled then
		mp.add_forced_key_binding("i", "set-start", function()
			start_time = mp.get_property_number("time-pos")
			mp.osd_message("clip start: " .. start_time, 3)
		end)
		mp.add_forced_key_binding("o", "set-end", function()
			end_time = mp.get_property_number("time-pos")
			mp.osd_message("clip end: " .. end_time, 3)
		end)
		mp.add_forced_key_binding("p", "nab", nab)
		nabber_enabled = true
		mp.osd_message("nabber: enabled")
	else
		mp.remove_key_binding("set-start")
		mp.remove_key_binding("set-end")
		mp.remove_key_binding("nab")
		nabber_enabled = false
		mp.osd_message("nabber: disabled")
	end
end

mp.add_key_binding("n", "toggle-nabber", toggle_nabber)
