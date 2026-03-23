<div class="zhezu-download-issue">
	{if $zhezuIssueGalleys && count($zhezuIssueGalleys) > 0}
		{foreach from=$zhezuIssueGalleys item=galley}
			<a class="zhezu-btn zhezu-btn-download-issue" href="{$galley->getBestGalleyId()|escape}">
				{translate key="plugins.generic.zhezuCustom.downloadFullIssue"} ({$galley->getGalleyLabel()|escape})
			</a>
		{/foreach}
	{/if}
</div>
