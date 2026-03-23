<script>
	$(function() {ldelim}
		$('#zhezuCustomSettingsForm').pkpHandler('$.pkp.controllers.form.AjaxFormHandler');
	{rdelim});
</script>

<form
	class="pkp_form"
	id="zhezuCustomSettingsForm"
	method="POST"
	action="{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="save"}"
>
	{csrf}

	{fbvFormArea id="zhezuCustomSettingsFormArea"}

		{fbvFormSection title="plugins.generic.zhezuCustom.settings.metrikaId" description="plugins.generic.zhezuCustom.settings.metrikaId.description"}
			{fbvElement type="text" id="yandexMetrikaId" value=$yandexMetrikaId label="plugins.generic.zhezuCustom.settings.metrikaId"}
		{/fbvFormSection}

		{fbvFormSection list="true"}
			{fbvElement type="checkbox" id="showArticleStats" value="1" checked=$showArticleStats label="plugins.generic.zhezuCustom.settings.showArticleStats"}
		{/fbvFormSection}

		{fbvFormSection list="true"}
			{fbvElement type="checkbox" id="showDownloadIssue" value="1" checked=$showDownloadIssue label="plugins.generic.zhezuCustom.settings.showDownloadIssue"}
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormButtons submitText="common.save"}
</form>
