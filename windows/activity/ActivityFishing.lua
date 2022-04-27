local ActivityFishing = class("ActivityFishing", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityFishing:ctor(parentGO, params)
	ActivityFishing.super.ctor(self, parentGO, params)
end

function ActivityFishing:getPrefabPath()
	return "Prefabs/Windows/activity/activity_fishing"
end

function ActivityFishing:initUI()
	self.autoFish = xyd.db.misc:getValue("activity_fishing_autoFish")
	self.autoFish = self.autoFish ~= nil and tonumber(self.autoFish) == 1 or false

	self:getUIComponent()
	ActivityFishing.super.initUI(self)
	self:initUIComponent()
	self:initEffect()
	self:register()
end

function ActivityFishing:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText", typeof(UISprite))
	self.resItem = go:NodeByName("resItem").gameObject
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = self.resItem:NodeByName("btnPlus").gameObject
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.btnPreview = go:NodeByName("btnPreview").gameObject
	self.btnCollect = go:NodeByName("btnCollect").gameObject
	self.labelCollect = self.btnCollect:ComponentByName("labelCollect", typeof(UILabel))
	self.btnCollectRedMark = self.btnCollect:NodeByName("redPoint").gameObject
	self.btnAward = go:NodeByName("btnAward").gameObject
	self.labelAward = self.btnAward:ComponentByName("labelAward", typeof(UILabel))
	self.btnAwardRedMark = self.btnAward:NodeByName("redPoint").gameObject
	self.btnFishing = go:NodeByName("btnFishing").gameObject
	self.btnFishingRedMark = self.btnFishing:NodeByName("redPoint").gameObject
	self.groupSkip = go:NodeByName("groupSkip").gameObject
	self.btnSkip = self.groupSkip:NodeByName("btnSkip").gameObject
	self.btnSkipChooseImg = self.btnSkip:ComponentByName("imgChoose", typeof(UISprite))
	self.labelSkip = self.groupSkip:ComponentByName("labelSkip", typeof(UILabel))
	self.groupTarget = go:NodeByName("groupTarget").gameObject
	self.targetBubble = self.groupTarget:NodeByName("bubble").gameObject
	self.targetFish = self.groupTarget:ComponentByName("icon", typeof(UISprite))
	self.targetFishEffect = self.groupTarget:NodeByName("effect").gameObject
	self.groupAward = go:NodeByName("groupAward").gameObject
	self.awardBubble = self.groupAward:NodeByName("bubble").gameObject
	self.targetAward = self.groupAward:ComponentByName("icon", typeof(UISprite))
	self.targetAwardNum = self.groupAward:ComponentByName("num", typeof(UILabel))
	self.targetAwardEffect = self.groupAward:NodeByName("effect").gameObject
	self.luxunEffect = go:NodeByName("luxunEffect").gameObject
	self.liubiaoEffect = go:NodeByName("liubiaoEffect").gameObject
	self.fishEffect = go:NodeByName("fishEffect").gameObject
	self.groupFishes = go:NodeByName("groupFishes").gameObject
	self.groupFishImgs = go:NodeByName("groupFishImgs").gameObject

	for i = 1, 6 do
		self["fish" .. i] = self.groupFishes:NodeByName("fish" .. i).gameObject
		self["fishImg" .. i] = self.groupFishImgs:ComponentByName("fish" .. i, typeof(UITexture))
	end

	self.mask = go:NodeByName("mask").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLabel = self.timeGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timeGroup:ComponentByName("endLabel", typeof(UILabel))
end

function ActivityFishing:initUIComponent()
	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	xyd.setUISpriteAsync(self.imgText, nil, "activity_fishing_text_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
		self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
	end, nil, true)
	xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

	self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

	for i = 1, 6 do
		xyd.setUITextureByNameAsync(self["fishImg" .. i], xyd.tables.activityFishingMainTable:getPic(i), true)
	end

	self.groupFishImgs:SetActive(false)

	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD)

	CountDown.new(self.timeLabel, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel.text = __("END")
	self.labelCollect.text = __("ACTIVITY_FISH_BUTTON01")
	self.labelAward.text = __("ACTIVITY_FISH_BUTTON02")
	self.labelSkip.text = __("ACTIVITY_FISH_AUTO")

	self.btnSkipChooseImg:SetActive(self.autoFish)
	self.btnAwardRedMark:SetActive(self.activityData:getAwardRedMark())
	self.btnCollectRedMark:SetActive(self.activityData:getCollectRedMark())
	self.btnFishingRedMark:SetActive(self.activityData:getFishableRedMark())
	self.mask:SetActive(false)
	self.groupSkip:GetComponent(typeof(UILayout)):Reposition()

	if xyd.Global.lang == "ja_jp" then
		self.labelAward.width = 140
	end
end

function ActivityFishing:initEffect()
	self.luxunEffect_ = xyd.Spine.new(self.luxunEffect)

	self.luxunEffect_:setInfo("activity_fishing_luxun_pifu02", function ()
		self.luxunEffect_:setRenderTarget(self.luxunEffect:GetComponent(typeof(UITexture)), 1)
		self.luxunEffect_:SetLocalScale(0.8, 0.8, 1)
		self.luxunEffect_:play("idle", 0)
	end)

	self.liubiaoEffect_ = xyd.Spine.new(self.liubiaoEffect)

	self.liubiaoEffect_:setInfo("activity_fishing_liubiao_pifu01", function ()
		self.liubiaoEffect_:setRenderTarget(self.liubiaoEffect:GetComponent(typeof(UITexture)), 1)
		self.liubiaoEffect_:SetLocalScale(0.9, 0.9, 1)
		self.liubiaoEffect_:play("idle", 0)
	end)

	self.targetFishEffect_ = xyd.Spine.new(self.targetFishEffect)

	self.targetFishEffect_:setInfo("activity_fishing_fx_yupp", function ()
		self.targetFishEffect_:setRenderTarget(self.targetFishEffect:GetComponent(typeof(UITexture)), 1)
		self.targetFishEffect_:play("get", 1)
	end)

	self.targetAwardEffect_ = xyd.Spine.new(self.targetAwardEffect)

	self.targetAwardEffect_:setInfo("activity_fishing_fx_award", function ()
		self.targetAwardEffect_:setRenderTarget(self.targetAwardEffect:GetComponent(typeof(UITexture)), 1)
		self.targetAwardEffect_:play("texiao02", 1)
	end)

	self.fishEffect_ = xyd.Spine.new(self.fishEffect)

	self.fishEffect_:setInfo("fx_fish_normal", function ()
		self.fishEffect_:setRenderTarget(self.fishEffect:GetComponent(typeof(UITexture)), 1)
		self.fishEffect_:play("normal", 0)
		self.fishEffect:SetActive(false)
	end)

	self.fish1_position = self.fish1.transform.localPosition

	function self.fish1_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x + 696, self.fish1_position.y, 0), 3))
		sequence:Insert(3, self.fish1.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x - 1392, self.fish1_position.y, 0), 6))
		sequence:Insert(10, self.fish1.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x + 696, self.fish1_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish1_seq2()
		end)
	end

	function self.fish1_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x + 696, self.fish1_position.y, 0), 3))
		sequence:Insert(3, self.fish1.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x - 1392, self.fish1_position.y, 0), 6))
		sequence:Insert(10, self.fish1.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish1.transform:DOLocalMove(Vector3(self.fish1_position.x + 696, self.fish1_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish1_seq1()
		end)
	end

	self.fish1_seq1()

	self.fish2_position = self.fish2.transform.localPosition

	function self.fish2_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x - 696, self.fish2_position.y, 0), 3))
		sequence:Insert(3, self.fish2.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x + 1392, self.fish2_position.y, 0), 6))
		sequence:Insert(10, self.fish2.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x - 696, self.fish2_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish2_seq2()
		end)
	end

	function self.fish2_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x - 696, self.fish2_position.y, 0), 3))
		sequence:Insert(3, self.fish2.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x + 1392, self.fish2_position.y, 0), 6))
		sequence:Insert(10, self.fish2.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish2.transform:DOLocalMove(Vector3(self.fish2_position.x - 696, self.fish2_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish2_seq1()
		end)
	end

	self.fish2_seq1()

	self.fish3_position = self.fish3.transform.localPosition

	function self.fish3_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x + 696, self.fish3_position.y, 0), 3))
		sequence:Insert(3, self.fish3.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x - 1392, self.fish3_position.y, 0), 6))
		sequence:Insert(10, self.fish3.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x + 696, self.fish3_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish3_seq2()
		end)
	end

	function self.fish3_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x + 696, self.fish3_position.y, 0), 3))
		sequence:Insert(3, self.fish3.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x - 1392, self.fish3_position.y, 0), 6))
		sequence:Insert(10, self.fish3.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish3.transform:DOLocalMove(Vector3(self.fish3_position.x + 696, self.fish3_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish3_seq1()
		end)
	end

	self.fish3_seq1()

	self.fish4_position = self.fish4.transform.localPosition

	function self.fish4_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x - 696, self.fish4_position.y, 0), 3))
		sequence:Insert(3, self.fish4.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x + 1392, self.fish4_position.y, 0), 6))
		sequence:Insert(10, self.fish4.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x - 696, self.fish4_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish4_seq2()
		end)
	end

	function self.fish4_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x - 696, self.fish4_position.y, 0), 3))
		sequence:Insert(3, self.fish4.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x + 1392, self.fish4_position.y, 0), 6))
		sequence:Insert(10, self.fish4.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish4.transform:DOLocalMove(Vector3(self.fish4_position.x - 696, self.fish4_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish4_seq1()
		end)
	end

	self.fish4_seq1()

	self.fish5_position = self.fish5.transform.localPosition

	function self.fish5_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x + 696, self.fish5_position.y, 0), 3))
		sequence:Insert(3, self.fish5.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x - 1392, self.fish5_position.y, 0), 6))
		sequence:Insert(10, self.fish5.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x + 696, self.fish5_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish5_seq2()
		end)
	end

	function self.fish5_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x + 696, self.fish5_position.y, 0), 3))
		sequence:Insert(3, self.fish5.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x - 1392, self.fish5_position.y, 0), 6))
		sequence:Insert(10, self.fish5.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish5.transform:DOLocalMove(Vector3(self.fish5_position.x + 696, self.fish5_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish5_seq1()
		end)
	end

	self.fish5_seq1()

	self.fish6_position = self.fish6.transform.localPosition

	function self.fish6_seq1()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x - 696, self.fish6_position.y, 0), 3))
		sequence:Insert(3, self.fish6.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x + 1392, self.fish6_position.y, 0), 6))
		sequence:Insert(10, self.fish6.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x - 696, self.fish6_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish6_seq2()
		end)
	end

	function self.fish6_seq2()
		local sequence = self:getSequence()

		sequence:Insert(0, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x - 696, self.fish6_position.y, 0), 3))
		sequence:Insert(3, self.fish6.transform:DOScale(Vector3(-1, 1, 0), 1))
		sequence:Insert(4, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x + 1392, self.fish6_position.y, 0), 6))
		sequence:Insert(10, self.fish6.transform:DOScale(Vector3(1, 1, 0), 1))
		sequence:Insert(11, self.fish6.transform:DOLocalMove(Vector3(self.fish6_position.x - 696, self.fish6_position.y, 0), 3))
		sequence:AppendCallback(function ()
			self.fish6_seq1()
		end)
	end

	self.fish6_seq1()
end

function ActivityFishing:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD)

		self.btnFishingRedMark:SetActive(self.activityData:getFishableRedMark())
	end)
	self:registerEvent(xyd.event.GO_FISHING, function (event)
		local lenSurprise = false
		local goldSurprise = false
		local num = math.floor(event.data.len * 100 + 0.1)

		if event.data.need_id and tostring(event.data.need_id) ~= "" and tostring(math.floor(xyd.tables.activityFishSurpriseTable:getLength(event.data.id)[1] * 100)) <= tostring(math.floor(event.data.len * 100 + 0.1)) and tostring(math.floor(event.data.len * 100 + 0.1)) <= tostring(math.floor(xyd.tables.activityFishSurpriseTable:getLength(event.data.id)[2] * 100)) and self.activityData.detail.fishs[event.data.id].surprise == nil then
			lenSurprise = true
			self.activityData.detail.fishs[event.data.id].surprise = 1
		end

		local goldLenRange = xyd.tables.activityFishingMainTable:getRange1(event.data.id)

		if goldLenRange[2][1] <= event.data.len or event.data.len <= goldLenRange[1][2] then
			if goldLenRange[2][1] <= event.data.len and self.activityData.detail.fishs[event.data.id].get_max == nil then
				goldSurprise = true
				self.activityData.detail.fishs[event.data.id].get_max = 1
			end

			if event.data.len <= goldLenRange[1][2] and self.activityData.detail.fishs[event.data.id].get_min == nil then
				goldSurprise = true
				self.activityData.detail.fishs[event.data.id].get_min = 1
			end
		end

		if lenSurprise then
			self.autoTime = nil
		end

		if self.autoFish and self.autoTime and self.autoTime > 0 then
			self.autoTime = self.autoTime - 1
		end

		local fish_Xbases = {
			50,
			55,
			58,
			55,
			50,
			43
		}
		local fish_lengthRange = xyd.tables.activityFishingMainTable:getLength(event.data.id)
		local halfValue = (fish_lengthRange[1] + fish_lengthRange[2]) / 2
		local offset = (event.data.len - halfValue) / halfValue
		local fish_Xscale = 0.4 + 0.2 * offset
		local fish_Xoffset = fish_Xbases[event.data.id] + fish_Xbases[event.data.id] / 2 * offset

		local function fishEffectCallback()
			if not self.autoTime or self.todayFirstTime then
				self.fishEffect:SetActive(true)
			else
				self.fishEffect:SetActive(false)
			end

			local sequence = self:getSequence(function ()
				self.luxunEffect_:changeAttachment("fish", self["fishImg" .. event.data.id])

				if self.activityData.firstTime == true then
					print("=============firstTiem")

					self.activityData.firstTime = false

					self.luxunEffect_:changeSlotTransform("fish", Vector3(fish_Xoffset - 10, 0, 0), Vector3(fish_Xscale, fish_Xscale, fish_Xscale))
				else
					self.luxunEffect_:changeSlotTransform("fish", Vector3(fish_Xoffset + 2, 0, 0), Vector3(fish_Xscale, fish_Xscale, fish_Xscale))
				end

				local function closeCallback()
					self.luxunEffect_:removeAttachment("fish")

					if event.data.need_id and tostring(event.data.need_id) ~= "" then
						local function completeCallback()
							self.groupAward:SetActive(false)

							if lenSurprise == true or goldSurprise == true and not self.autoTime then
								dump(goldSurprise)
								dump(self.autoTime)
								xyd.models.itemFloatModel:pushNewItems(event.data.items)
								self.liubiaoEffect_:play("refresh", 1, nil, function ()
									xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
										self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
									end, nil, true)
									xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

									self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

									self.groupAward:SetActive(true)
									self.targetAwardEffect_:play("texiao02", 1, nil, function ()
									end)

									self.targetAward.transform.localScale = Vector3(0, 0, 1)
									self.targetAwardNum.transform.localScale = Vector3(0, 0, 1)
									local seq1 = self:getSequence()

									seq1:Insert(0, self.targetAward.transform:DOScale(Vector3(1, 1, 1), 0.2))
									seq1:Insert(0, self.targetAwardNum.transform:DOScale(Vector3(1, 1, 1), 0.2))
									self.targetFishEffect_:play("bit", 1, nil, function ()
									end)

									self.targetFish.transform.localScale = Vector3(0.2, 0.2, 1)
									local seq = self:getSequence()

									seq:Insert(0, self.targetFish.transform:DOScale(Vector3(0.38, 0.38, 0.38), 0.18))
									seq:Insert(0.18, self.targetFish.transform:DOScale(Vector3(0.25, 0.25, 0.25), 0.12))
									self.luxunEffect_:play("idle", 0)
									self.liubiaoEffect_:play("idle", 0)
									self.mask:SetActive(false)
								end)
								self.targetFishEffect_:play("disappear", 1, nil, function ()
								end)

								local sequence1 = self:getSequence()

								sequence1:Insert(0, self.targetFish.transform:DOScale(Vector3(0, 0, 0), 0.2))
							else
								dump(goldSurprise)
								dump(self.autoTime)

								if not self.autoTime or self.todayFirstTime then
									local function alertCallCallback()
										if lenSurprise ~= true and goldSurprise ~= true then
											xyd.models.itemFloatModel:pushNewItems({
												event.data.items[2]
											})
										end

										self.liubiaoEffect_:play("refresh", 1, nil, function ()
											xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
												self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
											end, nil, true)
											xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

											self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

											self.groupAward:SetActive(true)
											self.targetAwardEffect_:play("texiao02", 1, nil, function ()
											end)

											self.targetAward.transform.localScale = Vector3(0, 0, 1)
											self.targetAwardNum.transform.localScale = Vector3(0, 0, 1)
											local seq1 = self:getSequence()

											seq1:Insert(0, self.targetAward.transform:DOScale(Vector3(1, 1, 1), 0.2))
											seq1:Insert(0, self.targetAwardNum.transform:DOScale(Vector3(1, 1, 1), 0.2))
											self.targetFishEffect_:play("bit", 1, nil, function ()
												if self.autoTime == 0 then
													self.autoTime = nil
												end

												if self.autoTime then
													self:clickBtnFishing()
												else
													self.mask:SetActive(false)
												end
											end)

											self.targetFish.transform.localScale = Vector3(0.2, 0.2, 1)
											local seq = self:getSequence()

											seq:Insert(0, self.targetFish.transform:DOScale(Vector3(0.38, 0.38, 0.38), 0.18))
											seq:Insert(0.18, self.targetFish.transform:DOScale(Vector3(0.25, 0.25, 0.25), 0.12))
											self.luxunEffect_:play("idle", 0)
											self.liubiaoEffect_:play("idle", 0)
										end)
										self.targetFishEffect_:play("disappear", 1, nil, function ()
										end)

										local sequence1 = self:getSequence()

										sequence1:Insert(0, self.targetFish.transform:DOScale(Vector3(0, 0, 0), 0.2))
									end

									if self.todayFirstTime then
										xyd.models.itemFloatModel:pushNewItems(event.data.items[1])
										alertCallCallback()
									else
										xyd.alertItems({
											event.data.items[1]
										}, alertCallCallback)
									end
								else
									dump(goldSurprise)
									dump(self.autoTime)

									if goldSurprise == true and self.autoTime then
										xyd.models.itemFloatModel:pushNewItems(event.data.items)
										xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
											self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
										end, nil, true)
										xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

										self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

										self.groupAward:SetActive(true)

										if self.autoTime == 0 then
											self.autoTime = nil
										end

										local awards = xyd.tables.miscTable:split2Cost("activity_fish_golden_awards", "value", "|#")
										local surpriseAwards = {}

										for i = 1, #awards do
											table.insert(surpriseAwards, {
												item_id = awards[i][1],
												item_num = awards[i][2]
											})
										end

										local function alertCallback()
											xyd.openWindow("gamble_rewards_window", {
												isNeedOptionalBox = false,
												wnd_type = 4,
												isNeedCostBtn = false,
												data = surpriseAwards,
												closeCallBack = function ()
													if self.autoTime then
														self:clickBtnFishing()
													end
												end
											})
											self:waitForTime(2.5, function ()
												local win = xyd.WindowManager.get():getWindow("gamble_rewards_window")

												if win then
													xyd.closeWindow("gamble_rewards_window")
												end
											end)
										end

										xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_FISH_GOLDEN_SURPRISE", xyd.tables.activityFishingTextTable:getName(event.data.id)), alertCallback, __("ACTIVITY_FISH_SURPRISE_BUTTON"), nil, , __("ACTIVITY_FISH_SURPRISE_TITLE"), nil, alertCallback)
										self:waitForTime(1.5, function ()
											local win = xyd.WindowManager.get():getWindow("alert_window")

											if win then
												xyd.closeWindow("alert_window")
											end
										end)

										if not self.autoTime then
											self.mask:SetActive(false)
										end

										return
									end

									xyd.models.itemFloatModel:pushNewItems(event.data.items)
									xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
										self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
									end, nil, true)
									xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

									self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

									self.groupAward:SetActive(true)

									if self.autoTime == 0 then
										self.autoTime = nil
									end

									if self.autoTime then
										self:clickBtnFishing()
									else
										self.mask:SetActive(false)
									end
								end
							end
						end

						if not self.autoTime or self.todayFirstTime then
							self.targetFishEffect_:play("get", 1, nil, function ()
							end)
							self.targetAwardEffect_:play("texiao01", 1, nil, completeCallback)
						else
							completeCallback()
						end
					else
						xyd.models.itemFloatModel:pushNewItems(event.data.items)
						self.luxunEffect_:play("idle", 0)
						self.liubiaoEffect_:play("idle", 0)

						if self.autoTime == 0 then
							self.autoTime = nil
						end

						if self.autoTime then
							if goldSurprise then
								xyd.setUISpriteAsync(self.targetFish, nil, xyd.tables.activityFishingMainTable:getPic(self.activityData.detail.need_id), function ()
									self.targetFish.transform.localScale = Vector3(0.25, 0.25, 1)
								end, nil, true)
								xyd.setUISpriteAsync(self.targetAward, nil, "icon_" .. self.activityData.detail.award[1])

								self.targetAwardNum.text = "x" .. tostring(self.activityData.detail.award[2])

								self.groupAward:SetActive(true)

								if self.autoTime == 0 then
									self.autoTime = nil
								end

								local awards = xyd.tables.miscTable:split2Cost("activity_fish_golden_awards", "value", "|#")
								local surpriseAwards = {}

								for i = 1, #awards do
									table.insert(surpriseAwards, {
										item_id = awards[i][1],
										item_num = awards[i][2]
									})
								end

								local function alertCallback()
									xyd.openWindow("gamble_rewards_window", {
										isNeedOptionalBox = false,
										wnd_type = 4,
										isNeedCostBtn = false,
										data = surpriseAwards,
										closeCallBack = function ()
											if self.autoTime then
												self:clickBtnFishing()
											end
										end
									})
									self:waitForTime(2.5, function ()
										local win = xyd.WindowManager.get():getWindow("gamble_rewards_window")

										if win then
											xyd.closeWindow("gamble_rewards_window")
										end
									end)
								end

								xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_FISH_GOLDEN_SURPRISE", xyd.tables.activityFishingTextTable:getName(event.data.id)), alertCallback, __("ACTIVITY_FISH_SURPRISE_BUTTON"), nil, , __("ACTIVITY_FISH_SURPRISE_TITLE"), nil, alertCallback)
								self:waitForTime(1.5, function ()
									local win = xyd.WindowManager.get():getWindow("alert_window")

									if win then
										xyd.closeWindow("alert_window")
									end
								end)

								if not self.autoTime then
									self.mask:SetActive(false)
								end
							else
								self:clickBtnFishing()
							end
						else
							self.mask:SetActive(false)
						end
					end

					if lenSurprise == true then
						local awards = xyd.tables.activityFishSurpriseTable:getAwards(event.data.id)
						local surpriseAwards = {}

						for i = 1, #awards do
							table.insert(surpriseAwards, {
								item_id = awards[i][1],
								item_num = awards[i][2]
							})
						end

						local function callback()
							xyd.openWindow("gamble_rewards_window", {
								isNeedOptionalBox = false,
								wnd_type = 4,
								isNeedCostBtn = false,
								data = surpriseAwards
							})
						end

						xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_FISH_LENGTH_SURPRISE", string.format("%.2f", event.data.len), xyd.tables.activityFishingTextTable:getName(event.data.id)), callback, __("ACTIVITY_FISH_SURPRISE_BUTTON"), nil, , __("ACTIVITY_FISH_SURPRISE_TITLE"), nil, callback)
					end

					if goldSurprise == true and not self.autoTime then
						local awards = xyd.tables.miscTable:split2Cost("activity_fish_golden_awards", "value", "|#")
						local surpriseAwards = {}

						for i = 1, #awards do
							table.insert(surpriseAwards, {
								item_id = awards[i][1],
								item_num = awards[i][2]
							})
						end

						local function callback()
							xyd.openWindow("gamble_rewards_window", {
								isNeedOptionalBox = false,
								wnd_type = 4,
								isNeedCostBtn = false,
								data = surpriseAwards
							})
						end

						xyd.alert(xyd.AlertType.CONFIRM, __("ACTIVITY_FISH_GOLDEN_SURPRISE", xyd.tables.activityFishingTextTable:getName(event.data.id)), callback, __("ACTIVITY_FISH_SURPRISE_BUTTON"), nil, , __("ACTIVITY_FISH_SURPRISE_TITLE"), nil, callback)
					end
				end

				if not self.autoTime then
					self.luxunEffect_:play("hit", 1, nil, function ()
						xyd.WindowManager:get():openWindow("activity_fishing_result_window", {
							id = event.data.id,
							len = event.data.len,
							closeCallBack = closeCallback
						})
					end)
				else
					self.luxunEffect_:play("hit", 1, 1.25, function ()
						closeCallback()
					end)
				end

				self.fishEffect:SetLocalPosition(-242, -600, 0)
				self.fishEffect:SetActive(false)
			end)

			if not self.autoTime or self.todayFirstTime then
				sequence:Insert(0, self.fishEffect.transform:DOLocalMove(Vector3(-180, -450, 0), 3))
			else
				sequence:Insert(0, self.fishEffect.transform:DOLocalMove(Vector3(-180, -450, 0), 0.01))
			end
		end

		if not self.autoTime or self.todayFirstTime then
			self.luxunEffect_:play("fish", 1, nil, fishEffectCallback)
		else
			fishEffectCallback()
		end

		self.btnAwardRedMark:SetActive(self.activityData:getAwardRedMark())
		self.btnCollectRedMark:SetActive(self.activityData:getCollectRedMark())
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self.btnAwardRedMark:SetActive(self.activityData:getAwardRedMark())
	end)

	UIEventListener.Get(self.resPlus).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.FISHING_ROD
		})
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_FISH_HELP"
		})
	end

	UIEventListener.Get(self.btnPreview).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_fishing_preview_window")
	end

	UIEventListener.Get(self.btnCollect).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_fishing_collect_window")

		self.activityData.collectUpdateMark = false

		self.btnCollectRedMark:SetActive(false)
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_FISHING, function ()
			self.activityData:getRedMarkState()
		end)
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		local all_info = {}
		local ids = xyd.tables.activityFishingAwardTable:getIDs()

		dump(self.activityData.detail.awards)
		dump(ids)

		for i = 1, #ids do
			local info = {
				id = ids[i],
				max_value = xyd.tables.activityFishingAwardTable:getComplete(ids[i])
			}
			info.cur_value = math.min(tonumber(self.activityData.detail.point), info.max_value)
			info.name = __("ACTIVITY_FISH_TOTAL_TEXT", math.floor(info.max_value))
			info.items = xyd.tables.activityFishingAwardTable:getAwards(ids[i])

			if self.activityData.detail.awards[i] == 0 then
				if info.cur_value == info.max_value then
					info.state = 1
				else
					info.state = 2
				end
			else
				info.state = 3
			end

			table.insert(all_info, info)
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("ACTIVITY_FISH_TOTAL_TITLE"),
			click_callBack = function (info)
				xyd.models.activity:reqAwardWithParams(self.id, cjson.encode({
					table_id = info.id
				}))
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.FISHING
		})
	end

	UIEventListener.Get(self.btnFishing).onClick = function ()
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD) < 5 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.FISHING_ROD)))

			return
		end

		if self.autoFish and not self.autoTime then
			local cost = {
				xyd.ItemID.FISHING_ROD,
				5
			}
			local max_num = math.floor(xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD) / 5)

			xyd.WindowManager.get():openWindow("common_use_cost_window", {
				select_multiple = 5,
				select_max_num = max_num,
				show_max_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD),
				icon_info = {
					height = 34,
					width = 34,
					name = "icon_" .. xyd.ItemID.FISHING_ROD
				},
				title_text = __("ACTIVITY_FISH_AUTO"),
				explain_text = __("ACTIVITY_FISH_AUTO_TEXT"),
				sure_callback = function (num)
					self.autoTime = num

					self:clickBtnFishing()

					local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

					if common_use_cost_window_wd then
						xyd.WindowManager.get():closeWindow("common_use_cost_window")
					end
				end
			})

			return
		end

		self:clickBtnFishing()
	end

	UIEventListener.Get(self.btnSkip).onClick = function ()
		self.autoFish = not self.autoFish

		self.btnSkipChooseImg:SetActive(self.autoFish)
		xyd.db.misc:setValue({
			key = "activity_fishing_autoFish",
			value = self.autoFish and 1 or 0
		})
	end

	UIEventListener.Get(self.luxunEffect).onClick = function ()
		self.luxunEffect_:play("point", 1, nil, function ()
			self.luxunEffect_:play("idle", 0)
		end)
	end

	UIEventListener.Get(self.liubiaoEffect).onClick = function ()
		self.targetFishEffect_:play("bit", 1, nil, function ()
		end)

		self.targetFish.transform.localScale = Vector3(0.2, 0.2, 1)
		local seq = self:getSequence()

		seq:Insert(0, self.targetFish.transform:DOScale(Vector3(0.38, 0.38, 0.38), 0.18))
		seq:Insert(0.18, self.targetFish.transform:DOScale(Vector3(0.25, 0.25, 0.25), 0.12))
	end

	UIEventListener.Get(self.groupTarget).onClick = function ()
		self.targetFishEffect_:play("bit", 1, nil, function ()
		end)

		self.targetFish.transform.localScale = Vector3(0.2, 0.2, 1)
		local seq = self:getSequence()

		seq:Insert(0, self.targetFish.transform:DOScale(Vector3(0.38, 0.38, 0.38), 0.18))
		seq:Insert(0.18, self.targetFish.transform:DOScale(Vector3(0.25, 0.25, 0.25), 0.12))
	end

	UIEventListener.Get(self.groupAward).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			showGetWays = false,
			show_has_num = true,
			itemID = self.activityData.detail.award[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityFishing:resizeToParent()
	ActivityFishing.super.resizeToParent(self)
	self:resizePosY(self.btnCollect, -781, -943)
	self:resizePosY(self.btnAward, -781, -943)
	self:resizePosY(self.btnFishing, -771, -933)
	self:resizePosY(self.groupSkip, -850, -1012)
end

function ActivityFishing:getSequence(complete)
	local sequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		if complete then
			complete()
		end
	end)

	if not self.sequence_ then
		self.sequence_ = {}
	end

	table.insert(self.sequence_, sequence)

	return sequence
end

function ActivityFishing:clickBtnFishing()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD) < 5 then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.FISHING_ROD)))

		return
	end

	if self.todayFirstTime then
		self.todayFirstTime = false

		xyd.db.misc:setValue({
			key = "activity_fishing_todayFirstTime",
			value = xyd.getServerTime()
		})
	elseif self.todayFirstTime == nil then
		local timeStamp = xyd.db.misc:getValue("activity_fishing_todayFirstTime")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			dump("今天第一次钓鱼")

			self.todayFirstTime = true
		else
			self.todayFirstTime = false
		end
	end

	local msg = messages_pb:go_fishing_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FISHING

	xyd.Backend.get():request(xyd.mid.GO_FISHING, msg)
	self.mask:SetActive(true)
end

function ActivityFishing:dispose()
	ActivityFishing.super.dispose(self)

	if self.sequence_ then
		for i = 1, #self.sequence_ do
			if self.sequence_[i] then
				self.sequence_[i]:Kill(false)

				self.sequence_[i] = nil
			end
		end
	end
end

return ActivityFishing
