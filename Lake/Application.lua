-- Copyright (c) 2009 Sebastian Nowicki <sebnow@gmail.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local Object = require("Lake.Object")
local Task = require("Lake.Task")

-- The application interface for the build engine
local Application = Object:clone{
	name = nil,
	lakefiles = nil,
	lakefile = nil,
	prerequisites = {},
	tasks = {},
}

--- Initialize a new application.
-- @param name the name of the application.
-- @return A new application.
function Application:new(name)
	local DEFAULT_LAKEFILES = {
		"lakefile", "Lakefile",
		"lakefile.lua", "Lakefile.lua"
	}
	self = Application:clone{
		name = name or "lake",
		lakefiles = DEFAULT_LAKEFILES,
	}
	return self
end

--- Invoke all tasks in args.
-- @param args a list of options, and tasks to be invoked.
function Application:run(args)
	-- Collect tasks to be run
	local targets = {}
	for _, task in ipairs(args or {}) do
		table.insert(targets, task)
	end
	-- Add default task if none were specified
	if #self.tasks == 0 then
		table.insert(targets, "default")
	end
	self:loadLakefile()
	-- Invoke all tasks
	for _, name in ipairs(targets) do
		self:invokeTask(name)
	end
end

--- Parse a lakefile.
function Application:loadLakefile()
	local file
	if self.lakefile then
		file = self.lakefile
	else
		file = self:findLakefile()
		self.lakefile = file
	end
	if file then
		self.lakefile = file
		local f = assert(loadfile(file))
		f()
	end
end

-- Attempt to resolve prerequisites in self.prerequisites to task
-- prerequisites
function Application:_resolvePrerequisites()
	for i, edge in ipairs(self.prerequisites) do
		local task, prerequisite = unpack(edge)
		if self.tasks[prerequisite] then
			task:enhance({self.tasks[prerequisite]})
			self.prerequisites[i] = nil
		end
	end
end

--- Define a new task.
--
-- This should be used from the lakefile, as opposed to using Task:new()
-- directly. It defines tasks in a textual manner (without actually creating
-- Task objects), tracking prerequisites. When a task is to be invoked, they
-- are resolved and real Task objects are created.
-- @param name the name of a task.
-- @param prerequisites the tasks this task depends on.
-- @param action the action to be executed.
function Application:defineTask(name, prerequisites, action)
	assert(name and type(name) == "string")
	local task = self.tasks[name] or Task:new(name, nil, action)
	self.tasks[name] = task
	-- prerequisites must be a table
	if type(prerequisites) == "string" then
		prerequisites = {prerequisites}
	end
	-- Track prerequisites for this task
	for _, prerequisite in ipairs(prerequisites or {}) do
		table.insert(self.prerequisites, {task, prerequisite})
	end
	-- Attempt to resolve prerequisites and add to task
	self:_resolvePrerequisites()
end

-- Split task name and argument list.
-- @param raw_args a task deifnition string, e.g. "foo[bar, baz]".
-- @return The name (e.g. "foo") and a list of arguments
-- (e.g. {"bar", "baz"}) or nil if no arguments are given.
local function parseTaskArguments(raw_args)
	-- Split task name and argument list (e.g. "[foo, bar]")
	local name, arg_list = raw_args:match("([^\[]+)%[(.-)%]")
	local args = {}
	if arg_list then
		-- Split argument list and add each element to args
		for arg in arg_list:gmatch("([^,]+)[%s,]*") do
			table.insert(args, arg)
		end
	end
	return name, args
end

--- Invoke a task.
-- If tasks have not yet been resolved, they will be now.
-- @param task a string representing the task to be invoked.
function Application:invokeTask(task)
	local name, args = parseTaskArguments(task)
	name = name or task
	-- Ensure all tasks are defined
	self:_resolvePrerequisites()
	if self.tasks[name] then
		self.tasks[name]:invoke(unpack(args))
	end
end

--- Find a lakefile to execute.
-- This searches self.lakefiles for possible lakefile filenames.
-- @return The path to a lakefile.
function Application:findLakefile()
	for _, file in ipairs(self.lakefiles) do
		local fp, _, code = io.open(file, "r")
		if code == nil then
			io.close(fp)
			return file;
		end
	end
end

return Application
