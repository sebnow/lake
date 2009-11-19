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

--- The base unit of work.
-- A task can depend on other tasks, and when invoked executes its action.
local Task = Object:clone()

--- The name of a task.
Task.name = nil
--- Other tasks this task depends on.
Task.prerequisites = {}
--- Actions to be executed for this task.
Task.actions = {}
--- Whether the task was already invoked. This gets reset when Task:enable()
-- is called.
Task.wasInvoked = false

--- Initialize a new task.
-- @param name the name of the task (required).
-- @param prerequisites a list of tasks this task depends on.
-- @param action the function to be called when the task is invoked.
-- @return A new task.
function Task:new(name, prerequisites, action)
	assert(name and type(name) == "string")
	return Task:clone{
		name = name,
		prerequisites = prerequisites or {},
		actions = {action}
	}
end

--- Execute the actions associated with this task.
-- This does not execute the actions of a task's prerequisites.
-- @param ... arguments to be passed to the action.
function Task:execute(...)
	for _, v in ipairs(self.actions) do
		v(self, ...)
	end
end

--- Invoke a task and its prerequisites.
-- The task will be executed when all prerequisites have been executed. It
-- will not be executed if it was already invoked before. To allow it to be
-- invoked again, use Task:enable().
-- @param ... arguments to be passed to all actions being executed.
-- @see Task:enable()
function Task:invoke(...)
	if not self.wasInvoked then
		self.wasInvoked = true
		self:_invokePrerequisites(...)
		self:execute(...)
	end
end

--- Add prerequisites and actions to a task.
-- @param prerequisites a list of prerequisites to be added.
-- @param actions a list of actions to be added.
function Task:enhance(prerequisites, actions)
	for _, task in ipairs(prerequisites or {}) do
		table.insert(self.prerequisites, task)
	end
	for _, action in ipairs(actions or {}) do
		table.insert(self.actions, action)
	end
end

-- Invoke a task's prerequisites.
function Task:_invokePrerequisites(...)
	for _, task in ipairs(self.prerequisites) do
		task:invoke(...)
	end
end

--- Enable a task to be invoked, even if it has already been invoked.
function Task:enable()
	self.wasInvoked = false
end

return Task
