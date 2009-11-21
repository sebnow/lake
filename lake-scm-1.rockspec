package = "Lake"
version = "scm-1"
description = {
	summary = "A Lua build system",
	detailed = [[
		A Lua build system inspired by Make and Rake. It is designed to
		be simple and extensible. This allows it to be used for anything
        dealing with tasks.
	]],
	license = "MIT",
	homepage = "http://sebnow.github.com/lake/",
	maintainer = "Sebastian Nowicki"
}
dependencies = {
	"lua >= 5.1",
}
source = {
	url = "git://github.com/sebnow/lake.git"
}
build = {
	type = "none",
	install = {
		lua = {
			["Lake.init"] = "Lake/init.lua",
			["Lake.Application"] = "Lake/Application.lua",
			["Lake.Task"] = "Lake/Task.lua",
			["Lake.Object"] = "Lake/Object.lua"
		},
		bin = {
			["lake"] = "bin/lake.lua"
		}
	}
}
