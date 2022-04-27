local SummonGiftbagItem = class("SummonGiftbagItem")

function SummonGiftbagItem:ctor(go, params, scroller)
	self.go = go
	self.scroller = scroller
	self.id = params.id
	self.point = params.point
	self.isCompleted = params.isCompleted

	self:getUIComponent()
	self:setProgress()
	self:setText()
	self:setIcon()
end

function SummonGiftbagItem:getUIComponent()
	local trans = self.go.transform
	self.progressPrize = trans:ComponentByName("progressPrize", typeof(UIProgressBar))
	self.progressLabel = trans:ComponentByName("progressPrize/progressLabel", typeof(UILabel))
	self.labelText01 = trans:ComponentByName("labelText01", typeof(UILabel))
	self.groupIcon = trans:Find("groupIcon")
end

function SummonGiftbagItem:setProgress()
	local total = xyd.tables.activityGachaTable:getPoint(self.id)
	local current = math.min(self.point, total)
	self.progressPrize.value = current / total
	self.progressLabel.text = tostring(current) .. " / " .. tostring(total)
end

function SummonGiftbagItem:setText()
	local target = xyd.tables.activityGachaTable:getPoint(self.id)
	self.labelText01.text = __("SUMMON_GIFTBAG_TEXT01", target)
end

function SummonGiftbagItem:setIcon()
	local awards = xyd.tables.activityGachaTable:getAwards(self.id)

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				labelNumScale = 1.2,
				hideText = true,
				show_has_num = true,
				itemID = data[1],
				num = data[2],
				uiRoot = self.groupIcon.gameObject,
				scale = Vector3(0.7037037037037037, 0.7037037037037037, 0.7037037037037037),
				dragScrollView = self.scroller
			}
			local icon = xyd.getItemIcon(item)

			if self.isCompleted then
				icon:setChoose(true)
			end
		end
	end
end

local ActivityContent = import(".ActivityContent")
local SummonGiftBag = class("SummonGiftBag", ActivityContent)

function SummonGiftBag:ctor(name, params)
	ActivityContent.ctor(self, name, params)
	self:getUIComponent()
	self:layout()
end

function SummonGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/summon_giftbag"
end

function SummonGiftBag:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.imgBg1 = go:ComponentByName("imgBg1", typeof(UITexture))
	self.roundLabel = go:ComponentByName("roundLabel", typeof(UILabel))
	self.labelText02 = go:ComponentByName("labelText02", typeof(UILabel))
	self.imgText01 = go:ComponentByName("imgText01", typeof(UITexture))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.scroller = go:NodeByName("scroller").gameObject
	self.scrollerView = self.scroller:GetComponent(typeof(UIScrollView))
	self.scroller_uiPanel = go:ComponentByName("scroller", typeof(UIPanel))
	self.groupPackage = self.scroller:NodeByName("groupPackage").gameObject
	self.summonPrizeItem = go:NodeByName("common_prize_item").gameObject
	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
end

function SummonGiftBag:layout()
	self:setImg()
	self:setText()
	self:setItems()

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		self.timeCount_ = import("app.components.CountDown").new(self.labelTime)

		self.timeCount_:setInfo({
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.labelText01:SetActive(false)
	end

	self.roundLabel.text = __("WISHING_POOL_GIFTBAG_TEXT02", self.activityData.detail.circle_times, xyd.tables.activityTable:getRound(self.id)[2])

	if xyd.Global.lang == "en_en" then
		self.labelTime.gameObject:SetLocalPosition(200, -310, 0)
		self.labelText01.gameObject:SetLocalPosition(210, -310, 0)
	end
end

function SummonGiftBag:setImg()
	local textPath = "Textures/activity_text_web/"
	local imgPath = "Textures/activity_web/summon_giftbag/"

	xyd.setUITextureAsync(self.imgBg, imgPath .. "summon_giftbag_bg01", function ()
		self.imgBg:MakePixelPerfect()
	end, false)
	xyd.setUITextureAsync(self.imgBg1, imgPath .. "summon_giftbag_bg02", function ()
		self.imgBg1:MakePixelPerfect()
	end, false)
	xyd.setUITextureByNameAsync(self.imgText01, "summon_giftbag_text01_" .. tostring(xyd.Global.lang), true)
end

function SummonGiftBag:setText()
	self.labelText01.text = __("TEXT_END")
	self.labelText02.text = __("SUMMON_GIFTBAG_TEXT02")
end

function SummonGiftBag:setItems()
	local completed = {}
	local inCompleted = {}
	local ids = xyd.tables.activityGachaTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local isCompleted = xyd.tables.activityGachaTable:getPoint(id) <= self.activityData.detail.point
		local item = {
			id = id,
			isCompleted = isCompleted,
			point = self.activityData.detail.point
		}

		if isCompleted then
			table.insert(completed, item)
		else
			table.insert(inCompleted, item)
		end
	end

	table.insertto(inCompleted, completed)

	for i in ipairs(inCompleted) do
		local tmp = NGUITools.AddChild(self.groupPackage.gameObject, self.summonPrizeItem)
		local item = SummonGiftbagItem.new(tmp, inCompleted[i], self.scrollerView)
	end

	self.summonPrizeItem:SetActive(false)
end

return SummonGiftBag
