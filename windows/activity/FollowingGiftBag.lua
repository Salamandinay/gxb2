local ActivityContent = import(".ActivityContent")
local FollowingGiftBag = class("FollowingGiftBag", ActivityContent)

function FollowingGiftBag:ctor(parentGO, params)
	self.fburl_zh_tw = "https://www.facebook.com/cht.gxb2/"
	self.fburl_en_en = "https://www.facebook.com/en.gxb2/"
	self.fburl_fr_fr = "https://www.facebook.com/fr.gxb2/"
	self.fburl_ko_kr = "https://www.facebook.com/ko.gxb2"
	self.fburl_de_de = "https://www.facebook.com/de.gxb2"
	self.fb_group_url_en_en = "https://www.facebook.com/groups/2440464579303244/"
	self.fb_group_url_fr_fr = "https://www.facebook.com/groups/1465533550276942"
	self.fb_group_url_ko_kr = "https://cafe.naver.com/gxb2kr"
	self.fb_group_url_de_de = "https://www.facebook.com/groups/704461843695808/"
	self.fburl = ""
	self.fb_group_url = ""
	self.lineurl = __("LINE_ID")
	self.twitterurl = __("TWITTER_ID")
	self.items = {}

	FollowingGiftBag.super.ctor(self, parentGO, params)
end

function FollowingGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/following_gift_bag"
end

function FollowingGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initUIComponent()
	self:euiComplete()
end

function FollowingGiftBag:getUIComponent()
	local go = self.go
	self.allUIWidget = self.go:GetComponent(typeof(UIWidget))
	local group = go:NodeByName("e:Group").gameObject
	self.imgBg = group:ComponentByName("imgBg", typeof(UITexture))
	self.scrollerContent_ = self.imgBg:NodeByName("scrollerContent_").gameObject
	self.scrollerContent_UIScrollView = self.imgBg:ComponentByName("scrollerContent_", typeof(UIScrollView))
	self.scrollerCon = self.scrollerContent_:NodeByName("scrollerCon").gameObject
	self.imgData_ = self.scrollerCon:ComponentByName("imgData_", typeof(UISprite))
	self.imgTitle_ = self.imgBg:ComponentByName("imgTitle_", typeof(UISprite))
	self.groupBtns_ = group:NodeByName("groupBtns_").gameObject
	self.imgIcon = self.groupBtns_:ComponentByName("imgIcon", typeof(UITexture))
	self.groupItem = self.imgIcon:NodeByName("groupItem").gameObject
	self.facebookBtn = self.groupBtns_:ComponentByName("facebookBtnCon/facebookBtn", typeof(UITexture))
	self.facebookBtn_button_label = self.facebookBtn:ComponentByName("button_label", typeof(UILabel))
	self.twitterBtn = self.groupBtns_:ComponentByName("twitterBtnCon/twitterBtn", typeof(UITexture))
	self.twitterBtn_button_label = self.twitterBtn:ComponentByName("button_label", typeof(UILabel))
	self.lineBtnCon = self.groupBtns_:ComponentByName("lineBtnCon", typeof(UIWidget))
	self.lineBtn = self.groupBtns_:ComponentByName("lineBtnCon/lineBtn", typeof(UITexture))
	self.lineBtn_button_label = self.lineBtn:ComponentByName("button_label", typeof(UILabel))
	self.numGroup = self.groupBtns_:NodeByName("e:Group").gameObject
	self.numGroup_bg = self.numGroup:ComponentByName("e:Image", typeof(UITexture))
	self.facebookCountLabel = self.numGroup:ComponentByName("facebookCountLabel", typeof(UILabel))
	self.fbGroupCountLabel = self.groupBtns_:ComponentByName("fbGroupCountLabel", typeof(UILabel))
	self.leftTipsIcon = self.groupBtns_:ComponentByName("leftTipsIcon", typeof(UITexture))
	self.rightTipsIcon = self.groupBtns_:ComponentByName("rightTipsIcon", typeof(UITexture))
end

function FollowingGiftBag:initUIComponent()
	local res_prefix = "Textures/activity_web/following_giftbag/"

	xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/following_giftbag_bg01_" .. xyd.Global.lang, function ()
		if xyd.Global.lang == "ja_jp" or xyd.Global.lang == "de_de" then
			self.imgBg.width = 696
		end
	end)
	xyd.setUISpriteAsync(self.imgData_, nil, "following_giftbag_award_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.imgTitle_, nil, "following_giftbag_title_" .. xyd.Global.lang, nil, , true)
	xyd.setUITextureAsync(self.imgIcon, res_prefix .. "following_giftbag_icon", function ()
	end)
	xyd.setUITextureByNameAsync(self.facebookBtn, "following_fb_btn", true)
	self.facebookBtn:X(self.facebookBtn.width / 2)
	xyd.setUITextureByNameAsync(self.twitterBtn, "following_twitter_btn", true)
	self.twitterBtn:X(self.twitterBtn.width / 2)

	local lineBtnImg = "following_line_btn"

	self.lineBtnCon:Y(-807)

	if xyd.Global.lang == "en_en" then
		lineBtnImg = "following_fb_group_btn"

		self.lineBtnCon:Y(-780)
	elseif xyd.Global.lang == "fr_fr" then
		lineBtnImg = "following_fb_group_btn"

		self.lineBtnCon:Y(-780)
	elseif xyd.Global.lang == "ja_jp" then
		lineBtnImg = "following_line_btn"
	elseif xyd.Global.lang == "ko_kr" then
		lineBtnImg = "following_cafe_btn"
	elseif xyd.Global.lang == "de_de" then
		lineBtnImg = "following_fb_group_btn"

		self.lineBtnCon:Y(-780)
	end

	xyd.setUITextureByNameAsync(self.lineBtn, lineBtnImg, true, function ()
		self.lineBtn:X(self.lineBtn.width / 2)

		self.lineBtnCon.width = self.lineBtn.width
		self.lineBtnCon.height = self.lineBtn.height
	end)
	xyd.setUITextureAsync(self.numGroup_bg, res_prefix .. "following_giftbag_fb_frame", function ()
	end)
	xyd.setUITextureAsync(self.leftTipsIcon, res_prefix .. "following_giftbag_fb_icon", function ()
	end)
	xyd.setUITextureAsync(self.rightTipsIcon, res_prefix .. "following_giftbag_line_icon", function ()
	end)

	if xyd.Global.lang == "ja_jp" then
		self.leftTipsIcon:SetActive(false)
		self.rightTipsIcon:SetActive(false)
	else
		self.leftTipsIcon:SetActive(true)
		self.rightTipsIcon:SetActive(true)
	end

	if xyd.Global.lang == "ja_jp" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ko_kr" or xyd.Global.lang == "de_de" then
		self.numGroup:SetActive(false)
	else
		self.numGroup:SetActive(true)
	end
end

function FollowingGiftBag:resizeToParent()
	FollowingGiftBag.super.resizeToParent(self)

	local allHeight = self.allUIWidget.height
	local bgHeight_y = 113

	if allHeight > 867 then
		bgHeight_y = 113 - (allHeight - 867)
	else
		bgHeight_y = 113 + allHeight - 867
	end

	if bgHeight_y < 0 then
		bgHeight_y = 0
	end

	self.imgBg:SetLocalPosition(0, bgHeight_y, 0)

	local shortNum = 30

	if xyd.Global.lang == "ja_jp" then
		shortNum = 30
	end

	self.groupBtns_:Y(shortNum + (-105 - shortNum) * self.scale_num_contrary)
end

function FollowingGiftBag:euiComplete()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.FOLLOWING_GIFTBAG, function ()
		self.activityData.isTouched = true
	end)

	UIEventListener.Get(self.facebookBtn.gameObject).onClick = handler(self, function ()
		self:reqAward()
	end)
	UIEventListener.Get(self.lineBtn.gameObject).onClick = handler(self, self.onClickLineBtn)
	UIEventListener.Get(self.twitterBtn.gameObject).onClick = handler(self, self.onClickTwitterBtn)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:setText()
	self:setAward()

	self.fburl = self["fburl_" .. tostring(xyd.Global.lang)]
	self.fb_group_url = self["fb_group_url_" .. tostring(xyd.Global.lang)]

	if xyd.Global.lang == "ja_jp" then
		self.facebookBtn:SetActive(false)
		self.twitterBtn:SetActive(true)
	else
		self.twitterBtn:SetActive(false)
	end
end

function FollowingGiftBag:onClickLineBtn(evt)
	if xyd.Global.lang == "en_en" or xyd.Global.lang == "ko_kr" or xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		if self.fb_group_url ~= nil then
			xyd.SdkManager.get():openBrowser(self.fb_group_url)
		end
	else
		if self.lineurl ~= nil then
			xyd.SdkManager.get():copyToClipboard(self.lineurl)
		end

		xyd.WindowManager.get():openWindow("alert_window", {
			noClose = true,
			alertType = xyd.AlertType.TIPS,
			message = __("COPY_SUCCESSFULLY"),
			confirmText = __("YES")
		})
	end
end

function FollowingGiftBag:onClickTwitterBtn()
	if self.twitterurl ~= nil then
		xyd.SdkManager.get():copyToClipboard(self.twitterurl)
	end

	xyd.WindowManager.get():openWindow("alert_window", {
		noClose = true,
		alertType = xyd.AlertType.TIPS,
		message = __("COPY_SUCCESSFULLY"),
		confirmText = __("YES")
	})
	self:reqAward()
end

function FollowingGiftBag:setText()
	local pre_text = __("ALREADY_FOLLOW")
	local count = self.activityData.detail.count or 0
	local follow_cnt = xyd.getRoughDisplayNumber(count)
	local content = pre_text .. tostring(follow_cnt)
	self.facebookCountLabel.text = content
	self.facebookBtn_button_label.text = __("CLICK_FOLLOW")
	self.lineBtn_button_label.text = __("LINE_ID")
	self.twitterBtn_button_label.text = __("TWITTER_ID")

	if xyd.Global.lang == "en_en" then
		local count = self.activityData.detail.group_count or 0
		self.fbGroupCountLabel.text = __("ALREADY_GROUP")
	end
end

function FollowingGiftBag:setAward()
	local award = xyd.tables.miscTable:split2Cost("facebook_follow_award", "value", "|#")

	for i, v in pairs(award) do
		local item = xyd.getItemIcon({
			show_has_num = true,
			uiRoot = self.groupItem,
			itemID = award[i][1],
			num = award[i][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		item:SetLocalScale(0.6, 0.6, 1)
		table.insert(self.items, item)
	end

	if self.activityData.detail.is_awarded and self.activityData.detail.is_awarded > 0 then
		for i, v in pairs(self.items) do
			self.items[i]:setChoose(true)
		end
	end
end

function FollowingGiftBag:reqAward()
	if self.fburl ~= nil then
		xyd.SdkManager.get():openBrowser(self.fburl)
	end

	if self.activityData.detail.is_awarded and self.activityData.detail.is_awarded > 0 then
		return
	end

	self:waitForTime(1, function ()
		xyd.models.activity:reqAward(self.id)
	end)
end

function FollowingGiftBag:onAward(event)
	local id = event.data.activity_id

	if id ~= self.id then
		return
	end

	local award = xyd.tables.miscTable:split2Cost("facebook_follow_award", "value", "|#")
	local awardparams = {}

	for i, v in pairs(award) do
		table.insert(awardparams, {
			item_id = award[i][1],
			item_num = award[i][2]
		})
	end

	if self.activityData.detail.is_awarded and self.activityData.detail.is_awarded > 0 then
		for i, v in pairs(self.items) do
			self.items[i]:setChoose(true)
		end
	end
end

return FollowingGiftBag
