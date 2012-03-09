class InterMineWidget

    # Inject wrapper inside the target div that we have control over.
    constructor: ->
        $(@el).html $ '<div/>',
            class: "inner"
            style: "height:572px;overflow:hidden"
        @el = "#{@el} div.inner"


# --------------------------------------------


class ChartWidget extends InterMineWidget

    chartOptions:
        fontName: "Sans-Serif"
        fontSize: 9
        width: 400
        height: 450
        legend: "bottom"
        colors: [ "#2F72FF", "#9FC0FF" ]
        chartArea:
            top: 30
        hAxis:
            titleTextStyle:
                fontName: "Sans-Serif"
        vAxis:
            titleTextStyle:
                fontName: "Sans-Serif"

    templates:
        normal:
            """
                <header>
                    <% if (title) { %>
                        <h3><%= title %></h3>
                    <% } %>
                    <% if (description) { %>
                        <p><%= description %></p>
                    <% } %>
                    <% if (notAnalysed > 0) { %>
                        <p>Number of Genes in this list not analysed in this widget: <span class="label label-info"><%= notAnalysed %></span></p>
                    <% } %>
                </header>
                <div class="content"></div>
            """
        noresults:
            "<p>The widget has no results.</p>"

    # Set the params on us and set Google load callback.
    # `service`:       http://aragorn.flymine.org:8080/flymine/service/
    # `id`:            widgetId
    # `bagName`:       myBag
    # `el`:            #target
    # `widgetOptions`: { "title": true/false, "description": true/false }
    constructor: (@service, @id, @bagName, @el, @widgetOptions = { "title": true, "description": true, "selectCb": (pq) => console.log pq }) ->
        super()
        google.setOnLoadCallback => @render()

    # Visualize the displayer.
    render: =>
        # Get JSON response by calling the service.
        $.getJSON "#{@service}list/chart",
            widget: @id
            list:   @bagName
            filter: ""
            token:  "" # Only public lists for now.
        , (response) =>
            # We have results.
            if response.results
                # Render the widget template.
                $(@el).html _.template @templates.normal,
                    "title":       if @widgetOptions.title then response.title else ""
                    "description": if @widgetOptions.description then response.description else ""
                    "notAnalysed": response.notAnalysed

                # Create the chart.
                chart = new google.visualization[response.chartType]($(@el).find("div.content")[0])
                chart.draw(google.visualization.arrayToDataTable(response.results, false), @chartOptions)

                # Add event listener on click the chart bar.
                if response.pathQuery?
                    google.visualization.events.addListener chart, "select", =>
                        pq = response.pathQuery
                        for item in chart.getSelection()
                            if item.row?
                                pq = pq.replace("%category", response.results[item.row + 1][0])
                                if item.column?
                                    pq = pq.replace("%series", response.results[0][item.column])
                                @widgetOptions.selectCb(pq)
            else
                $(@el).html _.template @templates.noresults


# --------------------------------------------


class EnrichmentWidget extends InterMineWidget

    formOptions:
        errorCorrection: "Holm-Bonferroni"
        pValue:          0.05
        dataSet:         "All datasets"

    errorCorrections: [ "Holm-Bonferroni", "Benjamini Hochberg", "Bonferroni", "None" ]
    pValues: [ 0.05, 0.10, 1.00 ]

    templates:
        normal:
            """
                <header>
                    <% if (title) { %>
                        <h3><%= title %></h3>
                    <% } %>
                    <% if (description) { %>
                        <p><%= description %></p>
                    <% } %>
                    <% if (notAnalysed > 0) { %>
                        <p>Number of Genes in this list not analysed in this widget: <span class="label label-info"><%= notAnalysed %></span></p>
                    <% } %>
                    <div class="form"></div>
                </header>
                <div class="content" style="overflow:auto;overflow-x:hidden;height:400px"></div>
            """
        form:
            """
                <form>
                    <div class="group" style="display:inline-block;margin-right:5px">
                        <label>Test Correction</label>
                        <select name="errorCorrection" class="span2">
                            <% for (var i = 0; i < errorCorrections.length; i++) { %>
                                <% var correction = errorCorrections[i] %>
                                <option value="<%= correction %>" <%= (options.errorCorrection == correction) ? 'selected="selected"' : "" %>><%= correction %></option>
                            <% } %>
                        </select>
                    </div>

                    <div class="group" style="display:inline-block;margin-right:5px">
                        <label>Max p-value</label>
                        <select name="pValue" class="span2">
                            <% for (var i = 0; i < pValues.length; i++) { %>
                                <% var p = pValues[i] %>
                                <option value="<%= p %>" <%= (options.pValue == p) ? 'selected="selected"' : "" %>><%= p %></option>
                            <% } %>
                        </select>
                    </div>

                    <div class="group" style="display:inline-block;margin-right:5px">
                        <label>Dataset</label>
                        <select name="dataSet" class="span2">
                            <option value="All datasets" selected="selected">All datasets</option>
                        </select>
                    </div>
                </form>
            """
        table:
            """
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th><%= label %></th>
                            <th>p-Value</th>
                            <th>Matches</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            """
        row:
            """
                <tr>
                    <td class="description"><%= row["description"] %></td>
                    <td class="pValue"><%= row["p-value"].toFixed(7) %></td>
                    <td class="matches" style="position:relative">
                        <span class="count label label-success" style="cursor:pointer"><%= row["matches"].length %></span>
                    </td>
                </tr>
            """
        matches:
            """
                <div class="popover" style="position:absolute;top:22px;right:0;z-index:1;display:block">
                    <div class="popover-inner" style="width:300px;margin-left:-300px">
                        <a style="cursor:pointer;margin:2px 5px 0 0" class="close">×</a>
                        <h3 class="popover-title"></h3>
                        <div class="popover-content">
                            <% for (var i = 0; i < matches.length; i++) { %>
                                <a href="#"><%= matches[i] %></a><%= (i < matches.length -1) ? "," : "" %>
                            <% } %>
                        </div>
                    </div>
                </div>
            """
        noresults:
            "<p>The widget has no results.</p>"

    # Set the params on us and render.
    # `service`:       http://aragorn.flymine.org:8080/flymine/service/
    # `id`:            widgetId
    # `bagName`:       myBag
    # `el`:            #target
    # `widgetOptions`: { "title": true/false, "description": true/false }
    constructor: (@service, @id, @bagName, @el, @widgetOptions = { "title": true, "description": true }) ->
        super()
        @render()

    # Visualize the displayer.
    render: =>
        $.getJSON "#{@service}list/enrichment",
            widget:     @id
            list:       @bagName
            correction: @formOptions.errorCorrection
            maxp:       @formOptions.pValue
            filter:     @formOptions.dataSet
            token:      ""
        , (response) =>
            # We have results.
            if response.results
                # Render the widget template.
                $(@el).html _.template @templates.normal,
                    "title":       if @widgetOptions.title then response.title else ""
                    "description": if @widgetOptions.description then response.description else ""
                    "notAnalysed": response.notAnalysed

                $(@el).find("div.form").html _.template @templates.form,
                    "options":          @formOptions
                    "errorCorrections": @errorCorrections
                    "pValues":          @pValues
                
                # How tall should the table be?
                height = $(@el).height() - $(@el).find('header').height() - 18

                # Render the table.
                $(@el).find("div.content").html($ _.template @templates.table,
                    "label": response.label
                ).css "height", "#{height}px"
                
                # Table rows.
                table = $(@el).find("div.content table")
                for row in response.results then do (row) =>
                    table.append tr = $ _.template @templates.row,
                        "row": row
                    td = tr.find("td.matches .count").click => @matchesClick td, row["matches"]

                # Set behaviors.
                $(@el).find("form select").change @formClick
            else
                $(@el).html _.template @templates.noresults

    # On form select option change, set the new options and re-render.
    formClick: (e) =>
        @formOptions[$(e.target).attr("name")] = $(e.target[e.target.selectedIndex]).attr("value")
        @render()

    # Show matches.
    matchesClick: (target, matches) =>
        target.after modal = $ _.template @templates.matches,
            "matches": matches
        modal.find("a.close").click -> modal.remove()


# --------------------------------------------


class window.Widgets

    # New Widgets client.
    # `service`: http://aragorn.flymine.org:8080/flymine/service/
    constructor: (@service) ->
        if not window.jQuery? then throw "jQuery not loaded"
        if not window._? then throw "underscore.js not loaded"
        if not window.google? then throw "Google API not loaded"

    # Chart Widget.
    # `id`:            widgetId
    # `bagName`:       myBag
    # `el`:            #target
    # `widgetOptions`: { "title": true/false, "description": true/false }
    chart: (opts...) =>
        # Load Google Visualization.
        google.load "visualization", "1.0",
            packages: [ "corechart" ]

        new ChartWidget(@service, opts...)
    
    # Enrichment Widget.
    # `id`:            widgetId
    # `bagName`:       myBag
    # `el`:            #target
    # `widgetOptions`: { "title": true/false, "description": true/false, "selectCb": function() {} }
    enrichment: (opts...) =>
        new EnrichmentWidget(@service, opts...)

    # All available Widgets.
    # `type`:          Gene, Protein
    # `bagName`:       myBag
    # `el`:            #target
    # `widgetOptions`: { "title": true/false, "description": true/false, "selectCb": function() {} }
    all: (type = "Gene", bagName, el, widgetOptions) =>
        $.getJSON "#{@service}widgets"
        , (response) =>
            # We have results.
            if response.widgets
                # For all that match our object type...
                for widget in response.widgets when type in widget.targets
                    # Create target element for individual Widget (slugify just to make sure).
                    widgetEl = widget.name.replace(/[^-a-zA-Z0-9,&\s]+/ig, '').replace(/-/gi, "_").replace(/\s/gi, "-").toLowerCase()
                    $(el).append $('<div/>', id: widgetEl, class: "widget span6")
                    
                    # What type is it?
                    switch widget.widgetType
                        when "chart"
                            new ChartWidget(@service, widget.name, bagName, "##{el} ##{widgetEl}", widgetOptions)
                        when "enrichment"
                            new EnrichmentWidget(@service, widget.name, bagName, "##{el} ##{widgetEl}", widgetOptions)