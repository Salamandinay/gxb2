local WindowManager = class("WindowManager")
local WindowTable = xyd.tables.windowTable
local Camera = UnityEngine.Camera
local GameObject = UnityEngine.GameObject
local AnimationType = {
	OPEN = 1,
	CLOSE = 2
}

function WindowManager.get()
	if not WindowManager.INSTANCE then
		WindowManager.INSTANCE = WindowManager.new()
	end

	return WindowManager.INSTANCE
end

function WindowManager:clearAllWnd()
	if not WindowManager.INSTANCE then
		return
	end

	self:closeAllWindows({
		main_window = true
	})
	self:closeWindow("main_window")
end

function WindowManager:clearInstance()
	if self.touchEffect then
		self.touchEffect:destroy()

		self.touchEffect = true
	end

	self.isDiapose_ = true

	if self.uiCamera_ then
		local uiCamera = self.uiCamera_:GetComponent(typeof(UICamera))
		uiCamera.onClick = nil
	end

	WindowManager.INSTANCE = nil
end

function WindowManager:ctor()
	self.ngui_ = GameObject.FindWithTag("Ngui")
	self.ngui_.transform.position = Vector3(0, 1000, 0)
	self.uiRoot_ = self.ngui_:GetComponent(typeof(UIRoot))
	self.nguiCamera_ = XYDUtils.FindGameObject("NguiCamera"):GetComponent(typeof(Camera))
	self.uiCamera_ = self.ngui_:ComponentByName("UICamera", typeof(Camera))
	self.uiLayers_ = {}
	self.windowMap_ = {}
	self.windowMainQueue_ = {}
	self.playingWindows_ = {}
	self.windowCaches_ = {}
	self.closingWindows_ = {}
	self.hideWindows_ = {}
	self.backNameStack_ = {}
	self.extraGuideWindow = {
		"exskill_guide_window",
		"common_trigger_guide_window"
	}
	self.topWindowHeight_ = 0
	self.bottomWindowHeight_ = 0
	self.toggleGroupID_ = 0
	self.windowStack = {}

	self:initRenderTexture()
	self:initClick()
end

function WindowManager:setChristmasEffect(gameObject, state)
	if xyd.SHOW_CHRISTMAS and state then
		local effect = xyd.Spine.new(gameObject)

		effect:setInfo("zhujiemian_xiaxue", function ()
			effect:play("animation", 0, 1)
		end)

		return effect
	end
end

function WindowManager:initRenderTexture()
	local blurTexture1 = ResCache.LoadRenderTexture(self.ngui_, "Textures/Misc/blurTexture")
	local blurTexture2 = UnityEngine.RenderTexture(math.floor(UnityEngine.Screen.width / 2), math.floor(UnityEngine.Screen.height / 2), 0)
	blurTexture2.anisoLevel = 0
	blurTexture2.format = blurTexture1.format
	blurTexture2.filterMode = blurTexture1.filterMode
	blurTexture2.depth = blurTexture1.depth
	self.rtFormat_ = blurTexture1.format
	self.rtFilterMode_ = blurTexture1.filterMode
	self.rtDepth_ = blurTexture1.depth
	self.blurTexture_ = blurTexture2
end

function WindowManager:initClick()
	local uiCamera = self.uiCamera_:GetComponent(typeof(UICamera))

	function uiCamera.onClick(gameObject)
		local hasClickEvent = UIEventListener.Get(gameObject).onClick ~= nil
		local mousePos = xyd.mouseWorldPos()

		reportLog2("x:" .. mousePos.x * 1000 .. " y:" .. (mousePos.y - 1000) * 1000)
		self:playClickAction(mousePos, hasClickEvent)

		if self:getWindow("main_window") then
			xyd.PartnerSoundController.get():clearTimeCount()
		end
	end

	if not self.touchEffect then
		local touchPanelNode = ResCache.AddGameObject(self.ngui_, "Prefabs/Components/touch_node")
		local panel = touchPanelNode:GetComponent(typeof(UIPanel))
		panel.depth = xyd.UILayerDepth.MAX
		local effectNode = touchPanelNode:NodeByName("effectNode").gameObject
		self.touchEffectParent = effectNode.transform
		self.touchEffect = xyd.Spine.new(effectNode)

		self.touchEffect:setInfo("fx_dianji", function ()
			self.touchEffect:SetActive(false)
		end)

		self.touchPanelNode_ = touchPanelNode
		self.touchEffectNode_ = effectNode
	end
end

function WindowManager:playClickAction(worldPos, flag)
	if not self.touchEffect or not self.touchEffect:getGameObject() then
		return
	end

	local texiao = flag and "texiao02" or "texiao01"

	self.touchEffect:SetActive(true)

	local pos = self.touchEffectParent:InverseTransformPoint(worldPos)

	self.touchEffect:SetLocalPosition(pos.x, pos.y, 0)
	self.touchEffect:play(texiao, 1, 1, function ()
		self.touchEffect:stop()
		self.touchEffect:SetActive(false)
	end, true)
end

function WindowManager:getTopPanel()
	return self.touchPanelNode_
end

function WindowManager:getTopEffectNode()
	return self.touchEffectNode_
end

function WindowManager:getActiveHeight()
	local height = self.uiRoot_.activeHeight

	if xyd.Global.maxHeight < height then
		height = xyd.Global.maxHeight
	end

	return height
end

function WindowManager:getActiveWidth()
	local sWidth, sHeight = xyd.getScreenSize()
	local width = self.uiRoot_.activeHeight / sHeight * sWidth

	if xyd.Global.maxWidth < width then
		width = xyd.Global.maxWidth
	end

	return width
end

function WindowManager:getUIRootHeight()
	local height = self.uiRoot_.activeHeight

	return height
end

function WindowManager:printWindows()
	for name, window in pairs(self.windowMap_) do
		__TRACE("===name====", name, window:getName())
	end
end

function WindowManager:openWindow(name, params, callback, skipAnimation)
	print(debug.traceback())

	if UNITY_EDITOR then
		print(" " .. name .. "  =================")
	end

	if name == nil or not WindowTable:hasWindow(name) then
		error("not has window: " .. tostring(name))

		return
	end

	local layerType = WindowTable:getLayerType(name)

	if not layerType then
		error("no layer type")

		return
	end

	local result, animWindow = self:isPlayingAnimation(AnimationType.CLOSE)

	if result and animWindow then
		-- Nothing
	end

	if self:isOpen(name) then
		self:updateWindow(name, params, callback, skipAnimation)

		return
	end

	local resource = WindowTable:getResource(name)
	local path = string.format("Prefabs/Windows/%s", resource)
	local layerType = WindowTable:getLayerType(name)
	local layer = self:getUILayer(layerType)
	local windowClass = WindowTable:getClass(name)
	local window = import("app.windows." .. windowClass).new(name, params)

	self:addWindow(window)
	self:checkMainWindowSound()
	self:recordWindow(name, true)

	local function comp_callback()
		if window:isDisposed() then
			return
		end

		local gameObject = ResCache.AddGameObject(layer, path)

		if not gameObject then
			__TRACE("no this window object", name)

			return nil
		else
			window:setSkipOpenAnimation(skipAnimation)
			window:willOpen()

			local params2 = {
				windowName = name
			}

			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.WINDOW_WILL_OPEN,
				params = params2
			})

			local panel = gameObject:GetComponent(typeof(UIPanel))

			NGUITools.SetPanelConstrainButDontClip(panel)

			local region = panel.baseClipRegion
			region.z = self:getActiveWidth()
			region.w = self:getActiveHeight()
			panel.baseClipRegion = region

			self:fixToggleGroups(gameObject)
			window:open(gameObject)

			if window:stackType() ~= nil and window:stackType() > 0 then
				self:stackWindow(window)
			end

			if self:getWindow(name) then
				self:onWindowShown(name)
				self:setPlayingAnimation(window, AnimationType.OPEN, true)
				window:playOpenAnimation(function ()
					if window.animationCallback_ then
						window.animationCallback_ = nil
					end

					self:setPlayingAnimation(window, AnimationType.OPEN, false)
					window:didOpen()
					xyd.EventDispatcher.inner():dispatchEvent({
						name = xyd.event.WINDOW_DID_OPEN,
						params = {
							windowName = name
						}
					})

					if callback then
						callback(window)
					end
				end)
			elseif callback then
				callback(nil)
			end

			return window
		end
	end

	local loadRes = self:checkWndRes(window, path)

	if #loadRes > 0 then
		print("download: " .. path)
		ResCache.DownloadAssets(resource, loadRes, function ()
			if self.isDiapose_ then
				return
			end

			xyd.WindowManager.get():closeWindow("res_loading_window")
			comp_callback()
		end, function (value)
			if self.isDiapose_ then
				return
			end

			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName(name)
			loading_win:setLoadProgress(name, value)
		end)
	else
		return comp_callback()
	end
end

function WindowManager:recordWindow(name, isOpen)
	local noRecordWindow = {
		xyd.getInputWindowName(),
		"res_loading_window",
		"loading_window",
		"alert_window",
		"system_alert_window"
	}

	if xyd.arrayIndexOf(noRecordWindow, name) < 1 then
		if isOpen then
			table.insert(xyd.Global.recordOpenWindows, name)

			if #xyd.Global.recordOpenWindows > 5 then
				table.remove(xyd.Global.recordOpenWindows, 1)
			end
		else
			table.insert(xyd.Global.recordCloseWindows, name)

			if #xyd.Global.recordCloseWindows > 5 then
				table.remove(xyd.Global.recordCloseWindows, 1)
			end
		end

		xyd.Global.recordTime = os.time()
	end
end

function WindowManager:stackWindow(win)
	local length = #self.windowStack
	local preWindow = nil

	if length > 0 then
		local preWinName = self.windowStack[length]
		preWindow = self:getWindow(preWinName)
	end

	table.insert(self.windowStack, win:getName())

	length = length + 1

	table.sort(self.windowStack, function (a, b)
		local stackA = xyd.tables.windowTable:stackType(a)
		local stackB = xyd.tables.windowTable:stackType(b)

		return stackA < stackB
	end)

	local topWinName = self.windowStack[length]

	if topWinName ~= win:getName() then
		win:updateDisplay(false)
	elseif preWindow then
		preWindow:updateDisplay(false)
	end
end

function WindowManager:checkWndRes(window, path)
	local resource = window:getloadAsset()
	local paths = xyd.arrayMerge(resource, {
		path
	})

	if ResManager.IsLocalAssets(paths) then
		return {}
	end

	return paths
end

function WindowManager:debugResLoading(name, callback)
	local updateRes = nil

	function updateRes(value)
		local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

		if not loading_win then
			xyd.WindowManager.get():openWindow("res_loading_window", {})

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName(name)
		end

		loading_win:setLoadProgress(name, value)
	end

	for i = 1, 10 do
		XYDCo.WaitForTime(0.1 * i, function ()
			updateRes(0.1 * i)

			if i == 10 then
				callback()
			end
		end, nil)
	end
end

function WindowManager:addWindow(window)
	local name = window:getName()
	self.windowMap_[name] = window
	local backType = window:backType()
	local layerType = window:layerType()

	if (layerType == xyd.UILayerType.FULL_SCREEN_UI or layerType == xyd.UILayerType.FLOATING_UI) and xyd.BacksType.UNKONOW < backType then
		local length = #self.windowMainQueue_
		local lastWindow = self.windowMainQueue_[length]

		if lastWindow then
			lastWindow:setNext(window)
			window:setLast(lastWindow)
		end

		self.windowMainQueue_[length + 1] = window
	end

	table.insert(self.backNameStack_, name)
	table.insert(xyd.Global.recordCurWindows, name)
end

function WindowManager:onWindowClosed(window, isCloseAll)
	local mainWindow = self:getWindow("main_window")
	local backType = window:backType()
	local layerType = window:layerType()
	self.closingWindows_[window:getName()] = nil

	if (layerType == xyd.UILayerType.FULL_SCREEN_UI or layerType == xyd.UILayerType.FLOATING_UI) and xyd.BacksType.UNKONOW < backType then
		local lastWindow = window:getLast()
		local nextWindow = window:getNext()

		if lastWindow ~= nil then
			if backType == xyd.BacksType.DEFAULT and lastWindow ~= nil then
				lastWindow:updateDisplay(true)
			end

			lastWindow:setNext(nextWindow)

			if not isCloseAll and mainWindow ~= nil then
				local hideType = WindowTable:hideType(lastWindow:getName())

				if hideType >= 0 then
					mainWindow:updateWindowDisplay(hideType)

					local statusNum = WindowTable:bottomBtnStatus(lastWindow:getName())

					if statusNum ~= -2 then
						mainWindow:onBottomBtnValueChange(statusNum, true, true)
					end
				else
					mainWindow:updateWindowDisplay()
				end
			end
		elseif not isCloseAll and mainWindow ~= nil and nextWindow == nil then
			mainWindow:updateWindowDisplay()
		end

		if nextWindow then
			nextWindow:setLast(lastWindow)
		end

		window:setLast(nil)
		window:setNext(nil)

		for index, w in ipairs(self.windowMainQueue_) do
			if w == window then
				table.remove(self.windowMainQueue_, index)

				break
			end
		end
	end

	if window:stackType() ~= nil and window:stackType() > 0 then
		self:openStackWindow(window)
	end
end

function WindowManager:openStackWindow(win)
	self:removeWindowFromList(self.windowStack, win:getName())

	if #self.windowStack > 0 then
		local preWinName = self.windowStack[#self.windowStack]
		local preWindow = self:getWindow(preWinName)

		if preWindow then
			preWindow:updateDisplay(true)
			preWindow:playOpenAnimation(function ()
			end)
		end
	end
end

function WindowManager:clearStackWindow()
	self.windowStack = {}
end

function WindowManager:removeWindowFromList(list, name)
	if list == nil then
		list = {}
	end

	local windowIndex = -1

	for idx in pairs(list) do
		local wname = list[idx]

		if wname == name then
			windowIndex = idx

			break
		end
	end

	if windowIndex >= 1 then
		table.remove(list, windowIndex)
	end

	return windowIndex
end

function WindowManager:popupWindow(window)
	local name = window:getName()
	local lastWindow1 = window:getLast()
	local nextWindow1 = window:getNext()

	if lastWindow1 then
		lastWindow1:setNext(nextWindow1)
	end

	if nextWindow1 then
		nextWindow1:setLast(lastWindow1)
	end

	for index, w in ipairs(self.windowMainQueue_) do
		if w == window then
			table.remove(self.windowMainQueue_, index)

			break
		end
	end

	local lastWindow2 = self.windowMainQueue_[#self.windowMainQueue_]

	if lastWindow2 then
		lastWindow2:setNext(window)
	end

	window:setLast(lastWindow2)
	window:setNext(nil)
	table.insert(self.windowMainQueue_, window)
end

function WindowManager:onWindowShown(name)
	local window = self:getWindow(name)

	if not window then
		return
	end

	local backType = window:backType()
	local layerType = window:layerType()

	if (layerType == xyd.UILayerType.FULL_SCREEN_UI or layerType == xyd.UILayerType.FLOATING_UI) and xyd.BacksType.UNKONOW < backType then
		local lastWindow = window:getLast()

		if backType == xyd.BacksType.DEFAULT and lastWindow ~= nil then
			lastWindow:updateDisplay(false)
		end

		local mainWindow = self:getWindow("main_window")

		if mainWindow ~= nil then
			local hideType = WindowTable:hideType(window:getName())

			if hideType > 0 then
				mainWindow:updateWindowDisplay(hideType)
			end
		end
	end
end

function WindowManager:hideAllWindow(excludes)
	local names = {}

	if excludes then
		for _, name in ipairs(excludes) do
			names[name] = true
		end
	end

	local hideWindowNames = {}

	for name, win in pairs(self.windowMap_) do
		if name and win.window_ and not names[name] then
			table.insert(hideWindowNames, win)
		end
	end

	for _, win in ipairs(hideWindowNames) do
		if win then
			win:moveAway()
			table.insert(self.hideWindows_, win)
		end
	end
end

function WindowManager:resumeHideAllWindow()
	for _, win in ipairs(self.hideWindows_) do
		if win then
			win:moveBack()
		end
	end

	self.hideWindows_ = {}
end

function WindowManager:getUILayer(layerType)
	local layer = self.uiLayers_[layerType]

	if tolua.isnull(layer) then
		layer = NGUITools.AddChild(self.ngui_, "WindowLayer_" .. layerType)
		layer.transform.localPosition = Vector3(0, 0, layerType * -500)
		self.uiLayers_[layerType] = layer
	end

	return layer
end

function WindowManager:getNgui()
	return self.ngui_
end

function WindowManager:isOpen(name)
	if self:getWindow(name) then
		return true
	end

	return false
end

function WindowManager:getWindow(name)
	return self.windowMap_[name]
end

function WindowManager:updateWindow(name, params, callback, skipAnimation)
	local window = self:getWindow(name)

	if not window:getNext() then
		window:update(params)

		if not skipAnimation then
			self:setPlayingAnimation(window, AnimationType.OPEN, true)
			window:playOpenAnimation(function ()
				if window.animationCallback_ then
					window.animationCallback_ = nil
				end

				self:setPlayingAnimation(window, AnimationType.OPEN, false)

				if callback then
					callback(window)
				end
			end)
		end
	else
		self:updateUpDownWindowsDisplay(window)
		self:popupWindow(window)
		window:adjustWindowDepth()
		window:update(params)
		window:updateDisplay(true)
		self:onWindowShown(name)
		self:setPlayingAnimation(window, AnimationType.OPEN, true)
		window:setSkipOpenAnimation(skipAnimation)
		window:playOpenAnimation(function ()
			if window.animationCallback_ then
				window.animationCallback_ = nil
			end

			self:setPlayingAnimation(window, AnimationType.OPEN, false)
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.WINDOW_DID_OPEN,
				params = {
					windowName = name
				}
			})

			if callback then
				callback(window)
			end
		end)
	end
end

function WindowManager:checkMainWindowSound()
	local needChange = false
	local needSuspendBGS = false

	for name, win in pairs(self.windowMap_) do
		local soundIDs = WindowTable:bgsSound(name)

		if next(soundIDs) and soundIDs[1] == -1 then
			needSuspendBGS = true
		end

		if name ~= "main_window" and name ~= "loading_window" then
			needChange = true
		end
	end

	if needSuspendBGS then
		xyd.SoundManager.get():suspendBGS()
	else
		xyd.SoundManager.get():resumeBGS()
	end

	if xyd.SoundManager.get():getCurBgID() ~= xyd.Global.bgMusic then
		needChange = false
	end

	if needChange then
		xyd.SoundManager.get():setMainWindowBg(xyd.tables.miscTable:getNumber("main_bg_volume", "value"))
	else
		xyd.SoundManager.get():setMainWindowBg(1)
	end
end

function WindowManager:closeWindow(name, callback, skipAnimation, isCloseAll)
	local complete = nil

	function complete(win)
		if callback then
			callback(win)
		end
	end

	local window = self.windowMap_[name] or self.closingWindows_[name]

	if not window then
		return complete(nil)
	end

	self:recordWindow(name)
	__TRACE("close " .. name)
	self:updateUpDownWindowsDisplay(window)
	window:beforeClose()
	window:willClose()

	self.closingWindows_[name] = window
	self.windowMap_[name] = nil

	table.removebyvalue(self.backNameStack_, name)
	table.removebyvalue(xyd.Global.recordCurWindows, name)

	local function cleanUp()
		if window:isRuntimeBlurBackground() then
			local bg = window.window_:NodeByName(xyd.WindowDefaultBgName)

			if not tolua.isnull(bg) then
				bg:SetActive(false)
			end
		end

		self:setPlayingAnimation(window, AnimationType.CLOSE, false)

		if not isCloseAll then
			window:excuteCallBack(isCloseAll)
		end

		window:dispose()
		window:didClose()
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.WINDOW_DID_CLOSE,
			params = {
				windowName = name
			}
		})
		self:onWindowClosed(window, isCloseAll)

		if callback then
			callback(window)
		end
	end

	self:setPlayingAnimation(window, AnimationType.CLOSE, true)

	if skipAnimation then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.WINDOW_WILL_CLOSE,
			params = {
				windowName = name
			}
		})
		cleanUp()
	else
		window:playCloseAnimation(cleanUp)
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.WINDOW_WILL_CLOSE,
			params = {
				windowName = name
			}
		})
	end

	self:checkMainWindowSound()
end

function WindowManager:updateUpDownWindowsDisplay(window)
	local lastWindow = window:getLast()

	if not lastWindow then
		return
	end

	local limit1 = 0
	local nextWindow = window:getNext()

	while nextWindow ~= nil and limit1 < 100 do
		if nextWindow:layerType() == xyd.UILayerType.FULL_SCREEN_UI then
			return
		end

		nextWindow = nextWindow:getNext()
		limit1 = limit1 + 1
	end

	local layerType = window:layerType()

	if layerType == xyd.UILayerType.FULL_SCREEN_UI then
		local limit2 = 0

		while lastWindow and limit2 < 100 do
			local layerType2 = lastWindow:layerType()

			if layerType2 == xyd.UILayerType.FULL_SCREEN_UI or layerType2 == xyd.UILayerType.FLOATING_UI then
				lastWindow:updateDisplay(true)

				if layerType2 == xyd.UILayerType.FULL_SCREEN_UI then
					break
				end
			end

			lastWindow = lastWindow:getLast()
			limit2 = limit2 + 1
		end
	end
end

function WindowManager:closeWindowsOnLayer(layerType, exclusions)
	exclusions = exclusions or {}
	local keys = table.keys(self.windowMap_)

	for i = #keys, 1, -1 do
		local key = keys[i]
		local window = self.windowMap_[key]

		if window:layerType() == layerType then
			local name = window:getName()

			if not exclusions[name] then
				self:closeWindow(name, nil, true)
			end
		end
	end
end

function WindowManager:getWindowsOnLayer(layerType)
	local results = {}

	for _, window in ipairs(self.windowMainQueue_) do
		if window:layerType() == layerType then
			table.insert(results, window)
		end
	end

	return results
end

function WindowManager:getWindowsOnLayers(layerTypes)
	local results = {}

	for _, window in ipairs(self.windowMainQueue_) do
		if layerTypes[window:layerType()] then
			table.insert(results, window)
		end
	end

	return results
end

function WindowManager:spcialWindow()
	return {
		"float_message_window",
		"float_message_window2"
	}
end

function WindowManager:getAllWindow()
	return self.windowMap_
end

function WindowManager:closeAllWindows(exclusions, updateMain)
	exclusions = exclusions or {}
	local spcialWindow = self:spcialWindow()

	for _, wnd in ipairs(spcialWindow) do
		exclusions[wnd] = true
	end

	local isLast = false
	local keys = table.keys(self.windowMap_)

	for i = #keys, 1, -1 do
		local key = keys[i]
		local window = self.windowMap_[key]

		if window then
			local name = window:getName()

			if not exclusions[name] then
				self:closeWindow(name, nil, true, true)
			end
		end
	end

	local keys2 = table.keys(self.closingWindows_)

	for i = #keys2, 1, -1 do
		local key = keys2[i]
		local window = self.closingWindows_[key]
		local name = window:getName()

		if not exclusions[name] then
			self:closeWindow(name, nil, true, true)
		end
	end

	local mainWindow = self:getWindow("main_window")

	if mainWindow then
		local length = #self.windowMainQueue_

		if updateMain or length == 0 then
			mainWindow:updateWindowDisplay()
		else
			local lastWindow = self.windowMainQueue_[length]
			local hideType = WindowTable:hideType(lastWindow:getName())

			if hideType >= 0 then
				mainWindow:updateWindowDisplay(hideType)
			else
				mainWindow:updateWindowDisplay()
			end
		end
	end
end

function WindowManager:cleanUp()
	self:closeAllWindows({
		main_window = true
	})
	self:closeWindow("main_window")

	for _, layer in pairs(self.uiLayers_) do
		if not tolua.isnull(layer) then
			layer:SetActive(false)
			UnityEngine.GameObject.Destroy(layer)
		end
	end

	self.uiLayers_ = {}
end

function WindowManager:isPlayingAnimation(animType, includeMsg)
	for windowName, state in pairs(self.playingWindows_) do
		if state.isPlaying and state.animType == animType and (includeMsg or WindowTable:getLayerType(windowName) ~= xyd.UILayerType.MSG_UI) then
			return true, state.window
		end
	end

	return false
end

function WindowManager:setPlayingAnimation(window, animType, isPlaying)
	self.playingWindows_[window:getName()] = {
		window = window,
		isPlaying = isPlaying,
		animType = animType
	}
end

function WindowManager:getUICamera()
	return self.uiCamera_
end

function WindowManager:getUICamera2()
	local uiCamera = self.uiCamera_:GetComponent(typeof(UICamera))

	return uiCamera
end

function WindowManager:windowBack()
	local length = #self.backNameStack_

	if length <= 0 then
		return
	end

	local curMids = xyd.MainController.get():getCurMids()

	if #curMids > 0 then
		return
	end

	if not xyd.GuideController.get():isGuideComplete() then
		return
	end

	if self.backNameStack_ then
		for i, wdName in pairs(self.backNameStack_) do
			if xyd.arrayIndexOf(self.extraGuideWindow, wdName) > -1 then
				return
			end
		end
	end

	local topWndName = ""

	for i = length, 1, -1 do
		local name = self.backNameStack_[i]
		local window = self:getWindow(name)

		if not window or not window:isTureOpen() then
			return
		end

		if name ~= "loading_window" and name ~= "float_message_window" and name ~= "float_message_window2" and name ~= "activity_point_tips_window" then
			local canBack = window:canBackClose()

			if not canBack then
				return
			else
				topWndName = name

				break
			end
		end
	end

	if topWndName == "" then
		return
	end

	if topWndName == "main_window" then
		xyd.systemAlert(xyd.AlertType.YES_NO, __("EXIT_GAME_TIPS"), function (yes)
			if yes then
				XYDUtils.QuitGame()
			end
		end)

		return
	end

	local wnd = self:getWindow(topWndName)

	if wnd then
		wnd:onClickEscBack()
	end
end

function WindowManager:getTopMargine()
	return self.topWindowHeight_
end

function WindowManager:getBottomMargine()
	return self.bottomWindowHeight_
end

function WindowManager:setWindowCache(name, cache)
	self.windowCaches_[name] = cache
end

function WindowManager:getWindowCache(name)
	return self.windowCaches_[name]
end

function WindowManager:closeThenOpenWindow(closeWindow, openWindow, params, callback)
	if closeWindow and closeWindow ~= openWindow then
		local window1 = self:getWindow(closeWindow)

		if window1 then
			self:closeWindow(closeWindow, nil, true)
		end
	end

	self:openWindow(openWindow, params, callback)
end

function WindowManager:getTopWindow(layerType)
	for index = #self.windowMainQueue_, 1, -1 do
		local window = self.windowMainQueue_[index]

		if not layerType or layerType == window:layerType() then
			return window
		end
	end

	return nil
end

function WindowManager:fixToggleGroups(go)
	local toggles = go:GetComponentsInChildren(typeof(UIToggle), true)
	local groups = {}

	for i = 0, toggles.Length - 1 do
		local toggle = toggles[i]
		local group = toggle.group

		if group ~= 0 then
			if not groups[group] then
				self.toggleGroupID_ = self.toggleGroupID_ + 1
				groups[group] = self.toggleGroupID_
			end

			toggle.group = groups[group]
		end
	end
end

function WindowManager:bluredWindowMaxLayerType()
	local bluredWindowMaxLayerType = -1

	for _, window in ipairs(self.windowMainQueue_) do
		if window:isRuntimeBlurBackground() then
			local name = window:getName()
			local layerType = WindowTable:getLayerType(name)

			if bluredWindowMaxLayerType < layerType then
				bluredWindowMaxLayerType = layerType
			end
		end
	end

	return bluredWindowMaxLayerType
end

function WindowManager:showBlurBackground(blurTextureCp, show)
	local blur = self.nguiCamera_:GetComponent(typeof(RapidBlurEffect))
	blur.enabled = show
	local targetTexture = nil

	if show then
		targetTexture = self.blurTexture_
	end

	self.nguiCamera_:GetComponent(typeof(Camera)).targetTexture = targetTexture
	xyd.CameraManager.get():getCamera():GetComponent(typeof(Camera)).targetTexture = targetTexture
	blurTextureCp.mainTexture = targetTexture
end

function WindowManager:screenToWorldPoint(positon)
	if positon.x < 0 then
		positon.x = 0
	elseif UnityEngine.Screen.width < positon.x then
		positon.x = UnityEngine.Screen.width
	end

	if positon.y < 0 then
		positon.y = 0
	elseif UnityEngine.Screen.height < positon.y then
		positon.y = UnityEngine.Screen.height
	end

	return self.nguiCamera_:ScreenToWorldPoint(positon)
end

return WindowManager
