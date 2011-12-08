class @QualityReport
	constructor: (@measure, @sub_id, @filters) ->
		@sub_id or= null
		@filters or= ActiveFilters.all()
	url: -> 
		base = "/measure/#{@measure}"
		if @sub_id? then "#{base}/#{@sub_id}" else base
	fetch: (extraParams, callback) ->
		params = $.extend({}, @filters, extraParams)
		$.getJSON this.url(), $.extend({}, @filters, params), (data) -> 
			callback(data)
	poll: (params, callback) ->
		ref = this
		this.fetch params, (response) ->
			pollParams = $.extend(params, {jobs: response.jobs})
			if response.complete
				callback(response.result)
			else
				setTimeout (-> ref.poll(pollParams, callback)), 3000

@Page = {
	onMeasureSelect: (measure_id) ->
	onMeasureRemove: (measure_id) ->
	onFilterChange: (qr, li) ->
	onReportComplete: (qr) ->
	onLoad: ->
	params: {}
}

@ActiveFilters = {
	all: ->
		ActiveFilters.findFilters(".filterItemList li.checked")
	providers: ->
		ActiveFilters.findFilters(".filterItemList li.checked[data-filter-type='provider']")
	nonProvider: ->
		ActiveFilters.findFilters(".findFilterList li:not([data-filter-type='provider'])")
	findFilters: (selector) ->
		filterElements = _.map $(selector), (el) -> 
			type: $(el).data("filter-type"), value: $(el).data("filter-value")
		filters = _.reduce filterElements, (memo, filter) ->
			filter_key = "#{filter.type}\[\]"
			memo[filter_key] = [] unless memo[filter_key]?
			memo[filter_key].push(filter.value)
			return memo
		, {}
		return filters
}

@Render = {
	fraction: (selector, data) ->
		selector.find(".numeratorValue").html(data.numerator)
		selector.find(".denominatorValue").html(data.denominator)
	
	percent: (selector, data) -> 
		percent = if data.denominator == 0 then data.denominator else  (data.numerator / data.denominator) * 100
		selector.html("#{Math.floor(percent)}%")
	
	barChart: (selector, data) ->
		numerator_width = 0
		denominator_width = 0
		exclusion_width = 0
		if data.patient_count != 0
			numerator_width = (data.numerator / data.patient_count) * 100
			denominator_width = ((data.denominator - data.numerator) / data.patient_count) * 100
			exclusion_width = (data.exclusions / data.patient_count) * 100
		selector.children("div.tableBarNumerator").animate(width: "#{numerator_width}%")
		selector.children("div.tableBarDenominator").animate(width: "#{denominator_width}%")
		selector.children("div.tableBarExclusion").animate(width: "#{exclusion_width}%")
}

makeListsExpandable = ->
	$(".groupList label").click ->
		$(this).toggleClass("open")
		$(this).siblings(".expandableList").toggle("blind")

makeMeasureListClickable = ->
	$(".measureItemList ul li").click ->
		$(this).toggleClass("checked")
		measure = $(this).attr("data-measure-id")
		sub_ids = $(this).data("sub-measures").split(",")
		if sub_ids.length != 0
			sub_ids = [null] 
		if $(this).hasClass("checked")
			Page.onMeasureSelect(measure)
			$.each sub_ids, (i, sub) ->
				qr = new QualityReport(measure, sub)
				qr.poll(Page.params, Page.onReportComplete)
		else
			Page.onMeasureRemove(measure)


makeFilterListsClickable = ->
	$(".filterItemList .selectAll").click ->
		# this runs before the other filterItemList click handler that checks/unchecks
		# so it's really "unchecked" when it has the class checked and vice versa
		allSelected = !$(this).hasClass("checked")
		$(this).siblings().each (i, el) ->
			$(el).toggleClass("checked", !allSelected)
			$(el).toggle();
	$(".filterItemList ul li").click ->
		$(this).toggleClass("checked")
		Page.onFilterChange(this)

	
# Load Page
$ ->
	makeMeasureListClickable()
	makeFilterListsClickable()
	makeListsExpandable()
	Page.onLoad();
