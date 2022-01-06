# Application coffeescript

$(document).ready ->

	# When document is ready, we need to load the root folder pane
	$("#left_pane .content").load('/update_folders/root.html')

	$(".folder_show").live "click", ()->
		p = $(this).attr("data-node")
		update_folder_contents(p)

	update_folder_contents = (p)->
		if p == "[ROOT]"
			$('#middle_pane .content').load('/update_phrases/list.html')
		else
			$('#middle_pane .content').load("/update_phrases/#{p}/list.html")
		true

	update_phrase_list = (p)->
		$.getJSON "/phrase/#{p}/data.json", (data)->
			$('#phrase_name').text(p)
			$("#refresh_phrase_button").attr("data-path", p)
			for k,v of data
				$("#phrase_placeholder_#{k}").text(v)
			window.phrase_selected = true

	$(".phrase_link").live "click", ->
		p = $(this).attr("data-phrase")
		update_phrase_list(p)

	$(".folder_link").live "click", ->
		path = $(this).attr("data-node")
		if $(this).attr("data-open") == undefined or $(this).attr("data-open") == "0"
			p = $(this).parent().parent()
			t = $(this)
			$.get "/update_folders/#{path}/list.html", (data)->			
				$(t).html("[-]")
				$(t).attr('data-open', "1")
				$(p).append(data)
		else
			$(this).html("[+]")
			$(this).parent().parent().find(".additional_folders").remove()
			$(this).removeAttr("data-open")

	$("#cancel_phrase").click ()->
		$("#edit_modal").fadeOut('fast')

	$("#add_phrase_button").live "click", ->
		$("#new_phrase_modal").fadeIn "fast", ()->
			$("#new_phrase_input").focus()
		node = $(this).attr("data-path")
		$("#new_phrase_path").text(node)

	$("#cancel_new_phrase").click ()->
		$("#new_phrase_input").val("")
		$("#new_phrase_modal").fadeOut("fast")

	$("#submit_new_phrase").click ()->
		path 				= $("#new_phrase_path").text()
		phrase_name = $("#new_phrase_input").val()
		if path == ""
			path = "__ROOT__"
		$.post "/add_phrase/#{path}/create.json", {name: phrase_name}, (data)->
			if data.success
				if path == "__ROOT__"
					update_phrase_list(phrase_name)
				else
					update_phrase_list("#{path}.#{phrase_name}")
				$("#refresh_phrases_button").click()
			else
				alert "An error occured while creating the new phrase."
			$("#new_phrase_modal").fadeOut "fast"
			$("#new_phrase_input").val("")

	$("#new_phrase_input").keypress (event)->
		switch event.which
			when 13 
				$("#submit_new_phrase").click()
				event.preventDefault()
			when 32 
				$(this).val($(this).val() + "_")
				event.preventDefault()



	$("#save_button_container a").click ()->
		$.getJSON "/savedata.json", (data)->
			if data.success
				$("#save_button_container a").fadeOut()
			else
				alert "An error occured while saving the locale files."

	$(".language_link").click (event)->
		if !window.phrase_selected   # we can't edit if there has been no phrase selected yet.
			return false
		language_name = $(this).attr("data-language-name")
		language 			= $(this).attr("data-language")
		phrase 				= $('#phrase_name').text()
		t 						= $("#phrase_placeholder_#{language}").text()

		$("#edit_modal #language").text(language_name)
		$("#edit_modal #language").attr("data-language", language)
		$("#edit_modal #phrase").text(phrase)
		$("#edit_modal textarea").val(t)

		$("#edit_modal").fadeIn('fast')

	$("#refresh_phrases_button").live "click", ()->
		p = $(this).attr("data-path")
		update_folder_contents(p)
	
	$("#refresh_phrase_button").live "click", ()->
		if $("#phrase_name").text() != "NO PHRASE SELECTED"
			p = $(this).attr("data-path")
			update_phrase_list(p)

	$("#mass_edit_button").live "click", ()->
		
		if window.mass_editing
			n = $("#phrase_name").text()
			if !window.has_mass_edits
				window.has_mass_edits = false
				window.mass_editing = false
				update_phrase_list(n)
				return false
			# The button was pushed again so we're going to save
			phrases = {}
			
			$("#phrase_table .me_editbox").each (index)->
				t = $(this).val()
				l = $(this).attr("data-language")
				phrases[l] = t
			$.post "/mass_update/#{n}.json", {phrases: phrases}, (data)->
				if data.success
					$("#save_button_container a").fadeIn()
					update_phrase_list(n)
					$("#refresh_phrases_button").click()
				else
					alert "An error occurred while updating the phrase."
					update_phrase_list(n)
				window.mass_editing = false	
				window.has_mass_edits = false
			return false
		if $("#phrase_name").text() != "NO PHRASE SELECTED"
			$("#phrase_table .phrase").each (index)->
				l = $(this).attr("data-language")
				text = $(this).text()
				$(this).html("<input type=\"text\" id=\"me_editbox_#{index}\" class=\"me_editbox\" data-language=\"#{l}\"/>")
				$("#me_editbox_#{index}").val(text);
				inputs = $("#phrase_table").find(':input')
				inputs.eq(0).focus()
				window.mass_editing = true

	$(".me_editbox").live "keypress", (event)->
		if event.which == 13
			inputs = $("#phrase_table").find(':input')
			inputs.eq( inputs.index(this)+1).focus()
			event.preventDefault()
		window.has_mass_edits = true
	$("#submit_phrase").click ()->
		language 			= $('#language').attr('data-language')
		phrase 				= $('#phrase_name').text()
		t 						= $('#edit_modal .box textarea').val()
		$.post "alter_phrase/#{language}/#{phrase}.json", {phrase: t}, (data)->
			if data.success
				$("#save_button_container a").fadeIn()
				update_phrase_list(phrase)
				$("#refresh_phrases_button").click()
			else
				alert "An error occurred while updating the phrase."
			$("#edit_modal").fadeOut('fast')