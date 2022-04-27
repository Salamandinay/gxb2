local BaseWindow = import(".BaseWindow")
local ActivityVoteMissionWindow = class("ActivityVoteMissionWindow", BaseWindow)
local ActivityVoteMissionItem = class("ActivityVoteMissionItem")
local cjson = require("cjson")

function ActivityVoteMissionItem:ctor(go, params, parent)
	self.go_ = go
	self.id_ = params.id
	self.parent_ = parent
	self.activity_id_ = params.activity_id
	self.cur_mission_award_ = params.mission_award
	self.cur_mission_count_ = params.mission_count
	self.table_ = params.table
	local itemTrans = self.go_.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progress = itemTrans:ComponentByName("progressPart", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progressPart/labelDesc", typeof(UILabel))
	self.btnGo_ = itemTrans:NodeByName("btnGo").gameObject
	self.btnGoLabel_ = itemTrans:ComponentByName("btnGo/label", typeof(UILabel))
	self.btnAward = itemTrans:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("label", typeof(UILabel))
	self.btnAwardMask = self.btnAward:ComponentByName("btnMask", typeof(UISprite))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.baseBg_ = itemTrans:Find("imgBg").gameObject
	self.iconRoot_ = itemTrans:Find("itemRoot").gameObject

	self:createChildren()

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.missionDesc_.fontSize = 20
	end
end

function ActivityVoteMissionItem:createChildren()
	local id = self.id_
	local cur_mission_count = math.min(self.cur_mission_count_, self.table_:getComplete(tonumber(id)))
	local progress = self.progress
	progress.value = cur_mission_count / self.table_:getComplete(tonumber(id))
	self.progressDesc_.text = cur_mission_count .. "/" .. self.table_:getComplete(tonumber(id))
	self.missionDesc_.text = __("ACTIVITY_WEDDING_MISSION_DESC_" .. id, self.table_:getComplete(tonumber(id)))

	self:updateBtnStatus(true)

	local itemGroup = self.iconRoot_
	local data = self.table_:getAward(id)
	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.64,
		uiRoot = itemGroup,
		itemID = data[1],
		num = data[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		clickCloseWnd = {
			"activity_vote_mission_window"
		},
		dragScrollView = self.parent_.scroller
	})
end

function ActivityVoteMissionItem:updateInfo(mission_count, mission_award)
	self.cur_mission_award_ = mission_award
	self.cur_mission_count_ = mission_count

	self:update()
end

function ActivityVoteMissionItem:update()
	local cur_mission_count = self.cur_mission_count_
	local id = self.id_
	local progress = self.progress
	progress.value = cur_mission_count / self.table_:getComplete(tonumber(id))
	self.progressDesc_.text = cur_mission_count .. "/" .. self.table_:getComplete(tonumber(id))

	self:updateBtnStatus()
end

function ActivityVoteMissionItem:updateBtnStatus(first)
	if first == nil then
		first = false
	end

	local id = self.id_
	local cur_mission_count = self.cur_mission_count_
	local cur_mission_award = self.cur_mission_award_
	local btnGo = self.btnGo_
	local btnAward = self.btnAward

	if cur_mission_award ~= 0 then
		btnGo:SetActive(false)
		btnAward:SetActive(true)
		xyd.setUISpriteAsync(btnAward:GetComponent(typeof(UISprite)), nil, "white_btn_60_60")
		xyd.setTouchEnable(btnAward, false)

		self.btnAwardLabel.text = __("ALREADY_GET_PRIZE")
		local label_display = self.btnAwardLabel
		label_display.color = Color.New2(960513791)
		label_display.effectColor = Color.New2(4294967295.0)

		self.btnAwardMask:SetActive(true)
	else
		local tmp = self.table_:getComplete(id)

		if cur_mission_count < tmp then
			btnAward:SetActive(false)
			btnGo:SetActive(true)

			self.btnGoLabel_.text = __("GO")

			UIEventListener.Get(btnGo).onClick = function ()
				local getWayID = nil

				if self.table_.getGetWayID then
					getWayID = self.table_:getGetWayID(id)
				end

				if getWayID and getWayID ~= 0 then
					local functionID = xyd.tables.getWayTable:getFunctionId(getWayID)

					if not xyd.checkFunctionOpen(functionID) then
						return
					end

					local windows = xyd.tables.getWayTable:getGoWindow(getWayID)
					local params = xyd.tables.getWayTable:getGoParam(getWayID)

					for i in pairs(windows) do
						if not params[i] then
							params[i] = {}
						end

						params[i].closeCallBack = function ()
							if xyd.models.activity:isOpen(xyd.ActivityID.ACTIVITY_VOTE2) then
								xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VOTE2)
							end
						end

						local windowName = windows[i]

						if windowName == "activity_window" then
							local data = xyd.models.activity:getActivity(params[i].select)

							if not data then
								xyd.showToast(__("ACTIVITY_OPEN_TEXT"))
							else
								local newParams = xyd.tables.activityTable:getWindowParams(params[i].select)

								if newParams ~= nil then
									params[i].onlyShowList = newParams.activity_ids
									params[i].activity_type = xyd.tables.activityTable:getType(newParams.activity_ids[1])
								end

								xyd.goToActivityWindowAgain(params[i])
							end
						else
							xyd.WindowManager.get():openWindow(windowName, params[i])
						end
					end

					local closeWnds = xyd.tables.getWayTable:getCloseWindow(getWayID)

					for _, wndName in pairs(closeWnds) do
						local win = xyd.WindowManager.get():getWindow(wndName)

						if win then
							win:close()
						end
					end
				else
					local win = self.table_:getGoWindow(id)
					local function_id = nil

					if win == "tavern_window" then
						function_id = xyd.FunctionID.TAVERN
					elseif win == "arena_window" then
						function_id = xyd.FunctionID.ARENA
					end

					if not xyd.checkFunctionOpen(function_id) then
						return
					end

					local params = self.table_:getGoWindowParams(id)

					function params.closeCallBack()
						local win = self.parent_.activityContent_

						win:updateInfo()
					end

					params.lastWindow = "activity_window"

					xyd.WindowManager.get():closeWindow("activity_vote_mission_window")
					xyd.WindowManager.get():closeWindow("make_coffee_mission_window")
					xyd.WindowManager.get():openWindow(win, params)
				end
			end
		else
			btnGo:SetActive(false)
			btnAward:SetActive(true)

			self.btnAwardLabel.text = __("GET2")

			UIEventListener.Get(self.btnAward).onClick = function ()
				xyd.setTouchEnable(self.btnAward, false)
				self.parent_:getAllAward()
			end
		end
	end
end

function ActivityVoteMissionWindow:ctor(name, params)
	ActivityVoteMissionWindow.super.ctor(self, name, params)

	self.item_list_ = {}
	self.activity_data_ = params.activity_data
	self.activityContent_ = params.activityContent
	self.table_ = params.table or xyd.tables.activityWeddingVoteMissionTable:get()

	self.eventProxy_:addEventListener(xyd.event.GET_WEDDING_MISSION_LIST, function (event)
		self.activity_data_.detail.mission_awarded = event.data.mission_awarded
		self.activity_data_.detail.mission_count = event.data.mission_count

		self:updateWindow()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self:updateWindow()

		local real_data = cjson.decode(event.data.detail)
		local mission_id = real_data.mission_id
		local item_data = self.table_:getAward(mission_id)

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = item_data[1],
				item_num = item_data[2]
			}
		})
	end)
end

function ActivityVoteMissionWindow:getUIComponents()
	local win = self.window_
	self.closeBtn = win:NodeByName("closeBtn").gameObject
	self.scroller = win:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = win:NodeByName("scroller/itemGroup").gameObject
	self.itemGroupLayout = self.itemGroup:GetComponent(typeof(UILayout))
	self.itemPrefab = win:NodeByName("missionItem").gameObject
	self.titleLabel = win:ComponentByName("titleLabel", typeof(UILabel))

	self.itemPrefab:SetActive(false)
end

function ActivityVoteMissionWindow:initWindow()
	ActivityVoteMissionWindow.super.initWindow(self)
	self:getUIComponents()
	ActivityVoteMissionWindow.super.register(self)
	self:initItems()

	local msg = messages_pb.get_wedding_mission_list_req()
	msg.activity_id = self.activity_data_.id

	xyd.Backend:get():request(xyd.mid.GET_WEDDING_MISSION_LIST, msg)

	self.titleLabel.text = __("WEDDING_VOTE_TEXT_3")
end

function ActivityVoteMissionWindow:initItems()
	local ids = self.table_:getIDs()
	local itemGroup = self.itemGroup
	local item_list = self.item_list_
	local activityData = self.activity_data_

	for i = 1, #ids do
		local itemRoot = NGUITools.AddChild(itemGroup, self.itemPrefab)
		local item = ActivityVoteMissionItem.new(itemRoot, {
			id = i,
			mission_award = activityData.detail.mission_awarded[i],
			mission_count = activityData.detail.mission_count[i],
			activity_id = self.activity_data_.id,
			table = self.table_
		}, self)

		xyd.setDragScrollView(item.go_, self.scroller)
		table.insert(item_list, item)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()
end

function ActivityVoteMissionWindow:updateWindow()
	local item_list = self.item_list_

	for i = 1, #item_list do
		local item = item_list[i]

		item:updateInfo(self.activity_data_.detail.mission_count[i], self.activity_data_.detail.mission_awarded[i])
	end
end

function ActivityVoteMissionWindow:getAllAward()
	for i = 1, #self.item_list_ do
		if self.activity_data_.detail.mission_awarded[i] == 0 and self.table_:getComplete(i) <= self.activity_data_.detail.mission_count[i] then
			local params = {
				type = 2,
				mission_id = i
			}
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = self.activity_data_.id
			msg.params = cjson.encode(params)

			xyd.Backend:get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		end
	end
end

return ActivityVoteMissionWindow
