{**
 * templates/frontend/pages/issue.tpl
 *
 * Issue detail page: breadcrumbs, cover, description,
 * full-issue PDF, table of contents grouped by sections.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl"}

<main class="zhezu-issue" role="main">

    {* ── Issue Header ── *}
    <div class="zhezu-issue__header">

        {* Cover Image *}
        {if $issue->getLocalizedCoverImageUrl()}
            <div class="zhezu-issue__cover">
                <img src="{$issue->getLocalizedCoverImageUrl()|escape}"
                     alt="{$issue->getLocalizedCoverImageAltText()|escape|default:''}"
                     loading="lazy" />
            </div>
        {/if}

        <div class="zhezu-issue__info">
            {* Title: Vol X, No Y (Year) *}
            <h1 class="zhezu-issue__title">
                {$issue->getLocalizedTitle()|escape|default:{translate key="plugins.themes.zhezujournal.issue.noTitle"}}
            </h1>

            {* Publication Date *}
            {if $issue->getDatePublished()}
                <p class="zhezu-issue__date">
                    {translate key="plugins.themes.zhezujournal.issue.published"}:
                    {$issue->getDatePublished()|date_format:$dateFormatLong}
                </p>
            {/if}

            {* Description *}
            {if $issue->getLocalizedDescription()}
                <div class="zhezu-issue__description">
                    {$issue->getLocalizedDescription()|strip_unsafe_html}
                </div>
            {/if}

            {* Download Full Issue PDF *}
            {if $issueGalleys|@count}
                <div class="zhezu-issue__galleys">
                    {foreach from=$issueGalleys item=galley}
                        <a class="zhezu-issue__galley-btn"
                           href="{url page="issue" op="download" path=$issue->getBestIssueId()|to_array:$galley->getBestGalleyId()}">
                            &#128196; {translate key="plugins.themes.zhezujournal.issue.downloadFull"}
                            ({$galley->getGalleyLabel()|escape})
                        </a>
                    {/foreach}
                </div>
            {/if}
        </div>
    </div>

    {* ── Table of Contents ── *}
    {if $publishedSubmissions|@count}
        <div class="zhezu-archive__toc">
            {foreach from=$publishedSubmissionsBySection item=sectionData}
                <section class="zhezu-archive__toc-section">
                    {* Section Title *}
                    <h2 class="zhezu-archive__toc-section-title">
                        {$sectionData.title|escape}
                    </h2>

                    <ul class="zhezu-archive__toc-list">
                        {foreach from=$sectionData.articles item=article}
                            {assign var=publication value=$article->getCurrentPublication()}
                            <li class="zhezu-archive__toc-item">
                                <div class="zhezu-archive__toc-item-content">
                                    {* Article Title *}
                                    <h3 class="zhezu-archive__toc-article-title">
                                        <a href="{url page="article" op="view" path=$article->getBestId()}">
                                            {$article->getLocalizedTitle()|escape}
                                        </a>
                                    </h3>

                                    {* Authors *}
                                    {if $article->getAuthorString()}
                                        <p class="zhezu-archive__toc-article-authors">
                                            {$article->getAuthorString()|escape}
                                        </p>
                                    {/if}

                                    {* Pages *}
                                    {if $publication->getData('pages')}
                                        <span class="zhezu-archive__toc-article-pages">
                                            {translate key="plugins.themes.zhezujournal.issue.pages"}:
                                            {$publication->getData('pages')|escape}
                                        </span>
                                    {/if}

                                    {* DOI *}
                                    {if $publication->getData('pub-id::doi')}
                                        <span class="zhezu-archive__toc-article-doi">
                                            DOI:
                                            <a href="https://doi.org/{$publication->getData('pub-id::doi')|escape}"
                                               target="_blank" rel="noopener">
                                                {$publication->getData('pub-id::doi')|escape}
                                            </a>
                                        </span>
                                    {/if}
                                </div>

                                {* PDF Button *}
                                <div class="zhezu-archive__toc-item-actions">
                                    {foreach from=$article->getGalleys() item=galley}
                                        {if $galley->isPdfGalley()}
                                            <a class="zhezu-archive__toc-pdf-btn"
                                               href="{url page="article" op="download" path=$article->getBestId()|to_array:$galley->getBestGalleyId()}"
                                               title="{translate key="plugins.themes.zhezujournal.article.downloadPdf"}">
                                                PDF
                                            </a>
                                        {/if}
                                    {/foreach}
                                </div>
                            </li>
                        {/foreach}
                    </ul>
                </section>
            {/foreach}
        </div>
    {else}
        <p class="zhezu-issue__empty">
            {translate key="plugins.themes.zhezujournal.issue.noArticles"}
        </p>
    {/if}

</main>

{include file="frontend/components/footer.tpl"}
