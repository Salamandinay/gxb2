local ShrineHurdleChooseWayWindow = class("ShrineHurdleChooseWayWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function ShrineHurdleChooseWayWindow:ctor(name, params)
	ShrineHurdleChooseWayWindow.super.ctor(self, name, params)
end

function ShrineHurdleChooseWayWindow:initWindow()
	self:getUIComponent()
	self:initWayState()
	self:initTop()

	self.windowTop = WindowTop.new(self.window_, self.name_, -10, true)

	self:register()
end

function ShrineHurdleChooseWayWindow:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end

	UIEventListener.Get(self.recordBtn_).onClick = function ()
		xyd.models.shrineHurdleModel:reqShineHurdleRecords()
	end

	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_GET_RECORDS, handler(self, self.onGetRecords))
end

function ShrineHurdleChooseWayWindow:onGetRecords(event)
	local records = event.data.records

	if not records or #records <= 0 then
		xyd.alertTips(__("TOWER_RECORD_TIP_1"))
	else
		local data = xyd.decodeProtoBuf(event.data)

		xyd.WindowManager.get():openWindow("shrine_hurdle_record_window", {
			records = data.records
		})
	end
end

function ShrineHurdleChooseWayWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.recordBtn_ = winTrans:NodeByName("recordBtn").gameObject
	self.wayItemList_ = {}

	for i = 1, 3 do
		self["way_item_" .. i] = winTrans:NodeByName("way_item_" .. i).gameObject
		local goTrans = self["way_item_" .. i]
		local params = {
			go = self["way_item_" .. i]
		}
		self["way_item_bg_" .. i] = goTrans:NodeByName("bg").gameObject
		self["chooseBtn" .. i] = goTrans:NodeByName("chooseBtn").gameObject
		params.titleLabel = goTrans:ComponentByName("titleLabel", typeof(UILabel))
		params.enviromentLabel = goTrans:ComponentByName("enviromentPart/enviromentLabel", typeof(UILabel))
		params.enviromentGroup = goTrans:ComponentByName("enviromentPart/enviromentGroup", typeof(UILayout))
		params.enviromentIcon1 = goTrans:ComponentByName("enviromentPart/enviromentGroup/icon1", typeof(UISprite))
		params.enviromentIcon2 = goTrans:ComponentByName("enviromentPart/enviromentGroup/icon2", typeof(UISprite))
		params.maxScoreTips = goTrans:ComponentByName("scorePart/maxScoreTips", typeof(UILabel))
		params.maxScore = goTrans:ComponentByName("scorePart/maxScore", typeof(UILabel))
		params.hardLevelTips = goTrans:ComponentByName("diffPart/hardLevelTips", typeof(UILabel))
		params.hardLevel = goTrans:ComponentByName("diffPart/hardLevel", typeof(UILabel))
		params.costLabel = goTrans:ComponentByName("chooseBtn/costLabel", typeof(UILabel))
		params.chooseBtn = goTrans:NodeByName("chooseBtn").gameObject
		params.chooseBtnLabel = goTrans:ComponentByName("chooseBtn/label", typeof(UILabel))
		params.partnerBtn = goTrans:NodeByName("partnerBtn").gameObject
		self.wayItemList_[i] = params

		UIEventListener.Get(params.chooseBtn).onClick = function ()
			self:onClickChooseBtn(i)
		end

		UIEventListener.Get(params.partnerBtn).onClick = function ()
			self:onClickPartnerBtn(i)
		end
	end

	self.enviromentShowPart = winTrans:NodeByName("enviromentShowPart").gameObject
	self.enviromentMaskBg = self.enviromentShowPart:NodeByName("maskBg").gameObject
	self.skillIcon = self.enviromentShowPart:ComponentByName("img", typeof(UISprite))
	self.labelNameSkill = self.enviromentShowPart:ComponentByName("skillName", typeof(UILabel))
	self.skillDesc = self.enviromentShowPart:ComponentByName("skillDesc", typeof(UILabel))

	UIEventListener.Get(self.enviromentMaskBg).onClick = function ()
		self.enviromentShowPart:SetActive(false)
	end
end

function ShrineHurdleChooseWayWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 100, false)

	self.windowTop:hideBg()

	local items = {
		{
			hidePlus = false,
			id = xyd.ItemID.SHRINE_TICKET
		}
	}

	self.windowTop:setItem(items)
end

function ShrineHurdleChooseWayWindow:initWayState()
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1

	for i = 1, 3 do
		local enviroments = xyd.tables.shrineHurdleRouteTable:getEnviroment(i, count)

		if xyd.models.shrineHurdleModel:checkInGuide() and i == 1 then
			enviroments = {
				500000,
				500001
			}
		end

		local params = self.wayItemList_[i]
		local icon1 = xyd.tables.skillTable:getSkillIcon(enviroments[1])
		local icon2 = xyd.tables.skillTable:getSkillIcon(enviroments[2])

		xyd.setUISpriteAsync(params.enviromentIcon1, nil, icon1)
		xyd.setUISpriteAsync(params.enviromentIcon2, nil, icon2)

		params.titleLabel.text = xyd.tables.shrineHurdleRouteTextTable:getTitle(enviroments[1])

		UIEventListener.Get(params.enviromentIcon1.gameObject).onClick = function ()
			self:onClickSkillIcon(enviroments[1], i)
		end

		UIEventListener.Get(params.enviromentIcon2.gameObject).onClick = function ()
			self:onClickSkillIcon(enviroments[2], i)
		end

		params.maxScoreTips.text = __("SHRINE_HURDLE_TEXT02")
		local maxScore = xyd.models.shrineHurdleModel:getMaxScore(i)
		params.maxScore.text = maxScore or 0
		params.hardLevelTips.text = __("SHRINE_HURDLE_TEXT03")
		params.hardLevel.text = xyd.models.shrineHurdleModel:getOverDiff(i)
		params.costLabel.text = "x " .. xyd.tables.shrineHurdleRouteTable:getCost(i)[2]
		params.enviromentLabel.text = __("SHRINE_HURDLE_TEXT01")
		params.chooseBtnLabel.text = __("SHRINE_HURDLE_TEXT04")
	end
end

function ShrineHurdleChooseWayWindow:onClickSkillIcon(skill_id, index)
	local icon1 = xyd.tables.skillTable:getSkillIcon(skill_id)

	xyd.setUISpriteAsync(self.skillIcon, nil, icon1)

	self.labelNameSkill.text = xyd.tables.shrineHurdleRouteTextTable:getName(skill_id)
	self.skillDesc.text = xyd.tables.shrineHurdleRouteTextTable:getDesc(skill_id)

	self.enviromentShowPart:SetActive(true)
	self.enviromentShowPart.transform:Y(540 - 340 * index)
end

function ShrineHurdleChooseWayWindow:onClickChooseBtn(index)
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex then
		xyd.WindowManager.get():openWindow("shrine_hurdle_choose_level_window", {
			route_id = 500000
		})

		return
	end

	local itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.SHRINE_TICKET)

	if not itemNum or itemNum <= 0 then
		xyd.alertTips(__("SWEETY_HOUSE_NEED_MORE", xyd.tables.itemTextTable:getName(xyd.ItemID.SHRINE_TICKET)))

		return
	end

	xyd.alertYesNo(__("SHRINE_HURDLE_TEXT05"), function (yes_no)
		if yes_no then
			xyd.WindowManager.get():openWindow("shrine_hurdle_choose_level_window", {
				route_id = index
			}, function ()
				self:close()
			end)
		end
	end)
end

return ShrineHurdleChooseWayWindow
