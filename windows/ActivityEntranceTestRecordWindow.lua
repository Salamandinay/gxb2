local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestRecordWindow = class("ActivityEntranceTestRecordWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ArenaRecordWindow = import(".ArenaRecordWindow")
local ItemRenderTest = class("ItemRenderTest", ArenaRecordWindow.ItemRender)
local ActivityEntranceTestRecordItem = class("ActivityEntranceTestRecordItem", ArenaRecordWindow.ArenaRecordItem)
local PlayerIcon = import("app.components.PlayerIcon")

function ItemRenderTest:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ActivityEntranceTestRecordItem.new(go)

	self.item:setDragScrollView(parent.scrollView)
end

function ActivityEntranceTestRecordItem:ctor(parentGo)
	ActivityEntranceTestRecordItem.super.ctor(self, parentGo)

	self.skinName = "activity_entrance_test_record_item"
end

function ActivityEntranceTestRecordItem:getPrefabPath()
	return "Prefabs/Components/activity_entrance_test_record_item"
end

function ActivityEntranceTestRecordItem:getUIComponent()
	local go = self.go
	local pIconContainer = go:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.time = go:ComponentByName("time", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.fight = go:NodeByName("fight").gameObject
	self.fightLabel = self.fight:ComponentByName("button_label", typeof(UILabel))
	self.fightBtnNum = self.fight:ComponentByName("btn_num", typeof(UILabel))
	self.fightIcon = self.fight:ComponentByName("icon", typeof(UISprite))
	self.loseImage = go:NodeByName("loseImage").gameObject
	self.winImage = go:NodeByName("winImage").gameObject
	self.video = go:NodeByName("video").gameObject
	self.serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))

	xyd.setUISpriteAsync(self.fightIcon, nil, xyd.tables.itemTable:getSmallIcon(xyd.ItemID.ENTRANCE_TEST_COIN))

	self.fightBtnNum.text = "1"
	self.fightLabel.text = __("FIGHT3")

	self:createChildren()
end

function ActivityEntranceTestRecordItem:setInfo(params, renderPanel)
	self.params = params

	if not self.pIcon then
		local pIconContainer = self.go:NodeByName("pIcon").gameObject
		self.pIcon = PlayerIcon.new(pIconContainer, renderPanel)
	end

	if params.is_robot == 1 then
		local robotInfo = xyd.tables.activityEntranceTestRobotTable:getAllInfo(params.player_id)

		self.pIcon:setInfo({
			avatarID = robotInfo.avatar,
			lev = robotInfo.lev
		})

		self.playerName.text = robotInfo.name
		self.serverId.text = robotInfo.server
		self.params.level = robotInfo.rank
	else
		self.pIcon:setInfo({
			avatarID = params.info_detail.avatar_id,
			lev = params.info_detail.lev,
			avatar_frame_id = params.info_detail.avatar_frame_id,
			callback = function ()
				self:onclickAvatar()
			end
		})

		self.playerName.text = params.info_detail.player_name
		self.serverId.text = xyd.getServerNumber(params.info_detail.server_id)
	end

	self.time.text = params.time
	local resTime = xyd.getServerTime() - params.time
	local min = resTime / 60
	local hour = min / 60
	local day = hour / 24

	if day >= 1 then
		self.time.text = __("DAY_BEFORE", math.floor(day))
	elseif hour >= 1 then
		self.time.text = __("HOUR_BEFORE", math.floor(hour))
	elseif min >= 1 then
		self.time.text = __("MIN_BEFORE", math.floor(min))
	else
		self.time.text = __("SECOND_BEFORE")
	end

	self.labelPoint.text = __("SCORE")
	local score = params.score > 0 and "+" .. tostring(params.score) or params.score
	self.point.text = score

	if params.is_win == 1 then
		self.currentState = "win"

		self:setState("win")
	else
		self.currentState = "lose"

		self:setState("lose")
	end

	if params.is_win == 1 then
		self.fight:SetActive(false)
	else
		local can_revenge_times = xyd.tables.miscTable:getNumber("activity_warmup_arena_revenge", "value")

		if params.challenge and can_revenge_times <= params.challenge then
			self.fight:SetActive(false)
		else
			self.fight:SetActive(true)
		end
	end
end

function ActivityEntranceTestRecordItem:onclickFight()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local times = activityData.detail.free_times

	if times <= 0 then
		xyd.showToast(__("ENTRANCE_TEST_FIGHT_TIP"))

		return
	end

	if self.params.level ~= activityData:getLevel() then
		xyd.showToast(__("ACTIVITY_ENTRANCE_TEST_RECORD_TIPS"))

		return
	end

	xyd.WindowManager:get():openWindow("battle_formation_window", {
		showSkip = true,
		is_revenge = 1,
		battleType = xyd.BattleType.ENTRANCE_TEST,
		mapType = xyd.MapType.ENTRANCE_TEST,
		enemy_id = self.params.player_id,
		index = self.params.index,
		skipState = xyd.checkCondition(tonumber(xyd.db.misc:getValue("entrance_test_skip_report")) == 1, true, false),
		btnSkipCallback = function (flag)
			local valuedata = xyd.checkCondition(flag, 1, 0)

			xyd.db.misc:setValue({
				key = "entrance_test_skip_report",
				value = valuedata
			})
		end
	})
end

function ActivityEntranceTestRecordItem:onclickAvatar()
end

function ActivityEntranceTestRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaRecordSkin"
	self.model_ = xyd.models.arena
end

function ActivityEntranceTestRecordWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:registerEvent()

	local msg = messages_pb:warmup_get_records_req()
	msg.activity_id = xyd.ActivityID.ENTRANCE_TEST

	xyd.Backend.get():request(xyd.mid.WARMUP_GET_RECORDS, msg)
end

function ActivityEntranceTestRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	self.backBtn_UIWidget = content:ComponentByName("backBtn", typeof(UIWidget))
	self.backBtn_BoxCollider = content:ComponentByName("backBtn", typeof(UnityEngine.BoxCollider))
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.renderPanel = self.scrollView:GetComponent(typeof(UIPanel))
	self.wrapContent_ = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	self.itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
	self.wrapContent = FixedWrapContent.new(self.scrollView, self.wrapContent_, self.itemContainer, ItemRenderTest, self)

	self.wrapContent:setInfos({}, {})

	self.backBtn_UIWidget.autoResizeBoxCollider = false
	self.backBtn_BoxCollider.size = Vector2(50, 50)
	local helpBtn = NGUITools.AddChild(content.gameObject, self.backBtn.gameObject)
	helpBtn.name = "helpBtn"

	helpBtn:SetLocalPosition(-313, 276, 0)

	self.helpBtn = helpBtn.gameObject:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.helpBtn, nil, "help_2", function ()
		self.helpBtn.width = 46
		self.helpBtn.height = 46
	end)
end

function ActivityEntranceTestRecordWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_RECORDS, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_ENTRANCE_TEST_RECORD_HELP"
		})
	end)
end

function ActivityEntranceTestRecordWindow:onGetData(event)
	dump(xyd.decodeProtoBuf(event.data), "测试数据")
	self:waitForFrame(1, function ()
		local data = xyd.decodeProtoBuf(event.data).records
		data = data or {}

		if #data == 0 then
			self.groupNone:SetActive(true)
		else
			self.groupNone:SetActive(false)

			for i in pairs(data) do
				data[i].index = i
			end
		end

		self.wrapContent:setInfos(data)
	end)
end

return ActivityEntranceTestRecordWindow
