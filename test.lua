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

require("telescope")

-- Look in the root directory first
package.path = "./?/init.lua;" .. package.path

local Lake = require("Lake")

-- Task tests
context("A Task", function()
	it("must have a name", function()
		assert_error(function()
			Lake.Task:new()
		end)
		local task = Lake.Task:new("aTask", nil, nil)
		assert_equal(task.name, "aTask")
	end)

	it("should accept a list of prerequisites", function()
		local prereqs = {Lake.Task:new("first")}
		local task = Lake.Task:new("aTask", prereqs, nil)
		assert_equal(task.prerequisites, prereqs)
	end)

	it("should execute its actions when invoked", function()
		local didExecute = false
		local task = Lake.Task:new("aTask", nil, function()
			didExecute = true
		end)
		task:invoke()
		assert_true(didExecute)
	end)

	it("should invoke its prerequisites", function()
		local executedTasks = {}
		local action =	function(t)
			table.insert(executedTasks, t.name)
		end
		local first = Lake.Task:new("first", nil, action)
		local second = Lake.Task:new("second", {first}, action)
		local third = Lake.Task:new("third", {second, first}, action)
		third:invoke()
		assert_equal(executedTasks[1], "first")
		assert_error(executedTasks[2], "second")
		assert_error(executedTasks[3], "third")
	end)

	it("should not execute on subsequent invocation", function()
		local timesExecuted = 0
		local task = Lake.Task:new("first", nil, function(t)
			timesExecuted = timesExecuted + 1
		end)
		task:invoke()
		task:invoke()
		assert_equal(timesExecuted, 1)
	end)

	it("should execute on subsequent invocation if enabled", function()
		local timesExecuted = 0
		local task = Lake.Task:new("first", nil, function(t)
			timesExecuted = timesExecuted + 1
		end)
		task:invoke()
		task:enable()
		task:invoke()
		assert_equal(timesExecuted, 2)
	end)

	it("should pass arguments to its action when invoked", function()
		local wanted = true
		local got = false
		local task = Lake.Task:new("task", nil, function(t, value)
			got = value
		end)
		task:invoke(wanted)
		assert_equal(wanted, got)
	end)
end)

-- Application tests
context("An Application", function()
	local application = nil
	before(function ()
		application = Lake.Application:new()
	end)

	it("should have zero tasks when created", function()
		assert_equal(#application.tasks, 0)
	end)

	it("should track tasks", function()
		application:defineTask("aTask")
		assert_not_nil(application.tasks["aTask"])
	end)

	it("should pass arguments to its tasks when run", function()
		local got = nil
		local wanted = "foobar"
		application:defineTask("default", nil, function(t, arg)
			got = arg
		end)
		application:invokeTask("default[foobar]")
		assert_equal(got, wanted)
	end)

	it("should correctly define prerequisites", function()
		order = {}
		action = function(t)
			table.insert(order, t.name)
		end
		application:defineTask("task4", {"task3", "task2"}, action)
		application:defineTask("task2", {"task1"}, action)
		application:defineTask("task1", nil, action)
		application:defineTask("task3", {"task2"}, action)
		application:invokeTask("task4")
		for num, task in ipairs(order) do
			assert_equal(task, "task" .. num)
		end
	end)
end)
