-- Module: Snap App. Hotkey
task = { apps={} }

function task.task(path, arg)
	return function()
		hs.task.new(path, nil, function() return false end, arg):start()
	end
end
function task.regist(modifier, table)
	for i, id in pairs(table) do
		local app = task.apps[id]
		if app then
			if type(app) == "string" then
				--app
				hs.hotkey.bind(modifier, tostring(i), function() hs.application.launchOrFocus(app) end)
			else
				--task
				hs.hotkey.bind(modifier, tostring(i), app)
			end
		end
	end
end

-- Module: Snap Window
window = {}
M = {MOVE=1, RESIZE=2}
D = {UP=1, DOWN=2, LEFT=3, RIGHT=4, CENTER=5}
W = {WIDTH=1, HEIGHT=2}
window.ratio_conf = {50, 66, 90, 33}
window.M, window.D = M, D

prev_m = nil
prev_d = nil
move = 0

function window.maximize()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local s = win:screen():frame()
	win:setFrame(s)
end

function window.move(method, direction)
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local s = win:screen():frame()
	--print("from: ", f)
	--print("screen: ", s)

	local way         -- resizing way
	local pos_r = 0   -- resized position ratio

	if direction == D.UP then
		way = W.HEIGHT
	elseif direction == D.DOWN then
		way = W.HEIGHT
		pos_r = 1
	elseif direction == D.LEFT then
		way = W.WIDTH
	elseif direction == D.RIGHT then
		way = W.WIDTH
		pos_r = 1
	else -- direction == D.CENTER then
		if s.w >= s.h then
			way = W.WIDTH
		else
			way = W.HEIGHT
		end
		pos_r = 0.5
	end

	if prev_m == method and prev_d == direction then
		move = move + 1
	else
		prev_m = method
		prev_d = direction
		move = 0
	end

	local ratio = window.ratio_conf[move % #window.ratio_conf + 1]/100
	--print("ratio: ", ratio)

	if way == W.WIDTH then
		f.x = s.x + s.w * (1-ratio)*pos_r
		f.w = s.w * ratio
	elseif way == W.HEIGHT then
		f.y = s.y + s.h * (1-ratio)*pos_r
		f.h = s.h * ratio
	end

	if method == M.MOVE then
		if way == W.WIDTH then
			f.y = s.y
			f.h = s.h
		elseif way == W.HEIGHT then
			f.x = s.x
			f.w = s.w
		end
	end

	prev_m = method
	prev_d = direction
	--print("to: ", f)
	win:setFrame(f)
end

function window.move_monitor(direction)
	local win = hs.window.focusedWindow()
	local m = nil
	if direction > 0 then
		m = win:screen():next()
	else
		m = win:screen():previous()
	end

	if m ~= win:screen() then
		win:moveToScreen(m, 0)
	end
end

function window.rotate_focus()
	-- get all windows of current app
	local app = hs.application.frontmostApplication()
	local windows = app:allWindows()
	table.sort(windows, function(a, b) return a:id() < b:id() end)

	local current = hs.window.focusedWindow()
	local current_index = nil
	for i, win in ipairs(windows) do
		if win:id() == current:id() then
			current_index = i
			break
		end
	end

	-- focus next window
	for i = 1, #windows do
		current_index = current_index + 1
		if current_index > #windows then
			current_index = 1
		end
		if windows[current_index]:isStandard() then
			break
		end
	end
	windows[current_index]:focus()
end

function window.raise_all()
	local app = hs.application.frontmostApplication()
	local windows = app:allWindows()

	for i, win in ipairs(windows) do
		if win:isStandard() then
			win:raise()
		end
	end
end

function window.regist()
	hs.hotkey.bind("option", "left", function() window.move(M.MOVE, D.LEFT) end)
	hs.hotkey.bind("option", "right", function() window.move(M.MOVE, D.RIGHT) end)
	hs.hotkey.bind("option", "up", function() window.move(M.MOVE, D.UP) end)
	hs.hotkey.bind("option", "down", function() window.move(M.MOVE, D.DOWN) end)
	hs.hotkey.bind({"option", "cmd"}, "left", function() window.move(M.RESIZE, D.LEFT) end)
	hs.hotkey.bind({"option", "cmd"}, "right", function() window.move(M.RESIZE, D.RIGHT) end)
	hs.hotkey.bind({"option", "cmd"}, "up", function() window.move(M.RESIZE, D.UP) end)
	hs.hotkey.bind({"option", "cmd"}, "down", function() window.move(M.RESIZE, D.DOWN) end)
	hs.hotkey.bind({"option", "shift"}, "left", function() window.move_monitor(-1) end)
	hs.hotkey.bind({"option", "shift"}, "right", function() window.move_monitor(1) end)
	hs.hotkey.bind({"option", "shift"}, "up", window.maximize)
	hs.hotkey.bind({"option", "shift"}, "down", function() window.move(M.MOVE, D.CENTER) end)
	hs.hotkey.bind("option", "tab", window.rotate_focus)
	hs.hotkey.bind({"option", "shift"}, "tab", window.raise_all)
end

return {
	task=task,
	window=window,
}
