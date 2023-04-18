script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import com.nuix.nx.NuixConnection
java_import com.nuix.nx.LookAndFeelHelper
java_import com.nuix.nx.dialogs.ChoiceDialog
java_import com.nuix.nx.dialogs.TabbedCustomDialog
java_import com.nuix.nx.dialogs.CommonDialogs
java_import com.nuix.nx.dialogs.ProgressDialog
java_import com.nuix.nx.dialogs.ProcessingStatusDialog
java_import com.nuix.nx.digest.DigestHelper
java_import com.nuix.nx.controls.models.Choice

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

require File.join(script_directory,"SuperUtilities.jar")
java_import com.nuix.superutilities.SuperUtilities
java_import com.nuix.superutilities.misc.FormatUtility
java_import com.nuix.superutilities.misc.PlaceholderResolver
$su = SuperUtilities.init($utilities,NUIX_VERSION)

case_tags = $current_case.getAllTags
tag_stats = []

# Given tags in the case, determine count of each tag so we can display that in the settings dialog
ProgressDialog.forBlock do |pd|
	pd.setMainStatus("Calculating tag stats...")
	case_tags.each do |tag|
		pd.setSubStatus("Counting tag '#{tag}'")
		item_count = $current_case.count("tag:\"#{FormatUtility.escapeTagForSearch(tag)}\"")
		if item_count > 0
			tag_stats << {
				:tag => tag,
				:count => item_count,
			}
		end
	end
	pd.dispose
end

# If we have no tags, just exit with error so we don't have to handle it beyond that
if tag_stats.size < 1
	CommonDialogs.showError("Current case has no tags.  Please apply some tags and re-run script.")
	exit 1
end

dialog = TabbedCustomDialog.new("Templated Sub-Tagger")

main_tab = dialog.addTab("main","Main")
main_tab.appendDynamicTable("input_tags","Input Tags",["Tag","Item Count"],tag_stats) do |record,column_index,set_value,value|
	if !set_value
		case column_index
		when 0
			next record[:tag]
		else
			next record[:count]
		end
	end
end


template_tab = dialog.addTab("template_tab","Template")
template_tab.appendTextField("template","Sub-Tag Template","{input_tag}|{kind_friendly}")

# Have guide to what placeholders are supported built right in next to template input
placeholder_guide_text =<<GUIDE
{input_tag} - The specified input tag which this item was responsive to.
{type} - The item's type name as obtained by ItemType.getLocalisedName
{mime_type} - The item's mime type as obtained by ItemType.getName
{kind} - The item's kind name as obtained by ItemType.getKind.getName
{kind_friendly} - The item's kind name as obtained by ItemType.getKind.getLocalisedName
{custodian} - The item's assigned custodian or NO_CUSTODIAN for items without a custodian assigned
{evidence_name} - The name of the evidence the item belongs to.
{item_date_short} - The item's item date formatted YYYYMMDD or NO_DATE for items without an item date.
{item_date_long} - The item's item date formatted YYYYMMdd-HHmmss or NO_DATE for items without an item date.
{item_date_year} - The item's item date 4 digit year or NO_DATE for items without an item date.
{item_date_month} - The item's item date 2 digit month or NO_DATE for items without an item date.
{item_date_day} - The item's item date 2 digit day of the month or NO_DATE for items without an item date.
{top_level_guid} - The GUID of the provided item's top level item or ABOVE_TOP_LEVEL for items which are above top level.
{top_level_name} - The name (via Item.getLocalisedName) of the provided item's top level item or ABOVE_TOP_LEVEL for
                   items which are above top level.
{top_level_kind} - The kind (via ItemType.getKind.getName) of the provided item's top level item or ABOVE_TOP_LEVEL for
                   items which are above top level.
{original_extension} - The original extension as obtained from Nuix via Item.getOriginalExtension or NO_ORIGINAL_EXTENSION for
                       items where Nuix does not have an original extension value.
{corrected_extension} - The corrected extension as obtained from Nuix via Item.getCorrectedExtension or NO_CORRECTED_EXTENSION for
                        items where Nuix does not have a corrected extension value.
{case_id} - The value obtained by calling Item.getCaseId which "Gets the case ID for the simple case that processed this item".
{case_name} - The value obtained by calling Item.getCaseName which gets the name of the simple case the item belongs to.

Less useful, but underlying logic can resolve them, so they are documented here for completeness:

{guid} - The item's GUID.
{guid_prefix} Characters 0-2 of the item's GUID. Useful for creating sub-groupings based on GUID.
{guid_infix} Characters 3-5 of the item's GUID. Useful for creating sub-groupings based on GUID.
{name} - The item's name as obtained by Item.getLocalisedName
{md5} - The item's MD5 or NO_MD5 for items without an MD5 value
GUIDE
template_tab.appendFormattedInformation("placeholder_guide","Placeholders",placeholder_guide_text)

# Validate user input
dialog.validateBeforeClosing do |values|
	if values["input_tags"].size < 1
		CommonDialogs.showWarning("Please select at least 1 input tag")
		return false
	end

	if values["template"].strip.empty?
		CommonDialogs.showWarning("Please provide a non-empty value for 'Sub-Tag Template'")
		return false
	end

	return true
end

# Show dialog
dialog.display
if dialog.getDialogResult == true
	values = dialog.toMap

	tags = values["input_tags"].map{|ts|ts[:tag]}
	template = values["template"]
	pr = PlaceholderResolver.new
	annotater = $utilities.getBulkAnnotater

	ProgressDialog.forBlock do |pd|
		tags.each_with_index do |tag, tag_index|
			pd.setMainStatusAndLogIt("#{tag_index+1}/#{tags.size} Processing Tag '#{tag}'")
			pd.setMainProgress(tag_index+1,tags.size)

			tag_batches = Hash.new{|h,k|h[k]=[]}

			tag_query = "tag:\"#{FormatUtility.escapeTagForSearch(tag)}\""
			tagged_items = $current_case.searchUnsorted(tag_query)
			if tagged_items.size < 1
				pd.logMessage("Tag query resulted in no items: "+tag_query)
				next
			end

			# Rather than adding each tag 1 at a time to each item as the tag is generated from
			# the resolved placeholder, we will instead batch items into groups based on the tag
			# to be applied.  This should generally result in fewer tagging calls.
			pd.setSubStatusAndLogIt("Resolving tag template into batches...")
			tagged_items.each_with_index do |item,item_index|
				pd.setSubProgress(item_index+1,tagged_items.size)
				pr.clear

				pr.setFromItem(item)
				pr.set("input_tag",tag)
				pr.set("kind_friendly",item.getKind.getLocalisedName)
				pr.set("case_id",item.getCaseId)
				pr.set("case_name",item.getCaseName)

				resolved_tag = pr.resolveTemplate(template)
				tag_batches[resolved_tag] << item
			end

			# Apply tags in batches
			pd.logMessage("Tagging #{tag_batches.size} batches...")
			batch_index = 0
			tag_batches.each do |tag,items|
				batch_index += 1
				pd.setSubStatusAndLogIt("Tagging #{items.size} items with tag '#{tag}'...")
				pd.setSubProgress(batch_index,tag_batches.size)

				annotater.addTag(tag,items)
			end
		end

		pd.setCompleted
	end
end