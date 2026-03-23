{**
 * templates/frontend/pages/article.tpl
 *
 * Article detail page: breadcrumbs, title, authors with ORCID,
 * DOI, dates, abstract, keywords, PDF download, stats,
 * references, license, citation.
 *}

{include file="frontend/components/header.tpl"}

{include file="frontend/components/breadcrumbs.tpl"}

<main class="zhezu-article" role="main">

    {* ── Article Title ── *}
    <h1 class="zhezu-article__title">
        {$article->getLocalizedTitle()|escape}
        {if $article->getLocalizedSubtitle()}
            <span class="zhezu-article__subtitle">
                {$article->getLocalizedSubtitle()|escape}
            </span>
        {/if}
    </h1>

    {* ── Authors ── *}
    {if $publication->getData('authors')|@count}
        <div class="zhezu-article__authors">
            {foreach from=$publication->getData('authors') item=author}
                <div class="zhezu-article__author">
                    <span class="zhezu-article__author-name">
                        {$author->getFullName()|escape}
                    </span>

                    {if $author->getData('orcid')}
                        <span class="zhezu-article__author-orcid">
                            <a href="{$author->getData('orcid')|escape}"
                               target="_blank" rel="noopener"
                               aria-label="ORCID {$author->getFullName()|escape}">
                                <img src="{$baseUrl}/plugins/themes/zhezujournal/images/orcid.svg"
                                     alt="ORCID" width="16" height="16" />
                            </a>
                        </span>
                    {/if}

                    {if $author->getLocalizedData('affiliation')}
                        <span class="zhezu-article__author-affiliation">
                            {$author->getLocalizedData('affiliation')|escape}
                        </span>
                    {/if}

                    {if $author->getData('country')}
                        <span class="zhezu-article__author-country">
                            {$author->getData('country')|escape}
                        </span>
                    {/if}
                </div>
            {/foreach}
        </div>
    {/if}

    {* ── DOI ── *}
    {if $publication->getData('pub-id::doi')}
        <div class="zhezu-article__doi">
            <span class="zhezu-article__doi-label">DOI:</span>
            <a href="https://doi.org/{$publication->getData('pub-id::doi')|escape}"
               target="_blank" rel="noopener">
                {$publication->getData('pub-id::doi')|escape}
            </a>
        </div>
    {/if}

    {* ── Dates ── *}
    <div class="zhezu-article__dates">
        {if $article->getDateSubmitted()}
            <div class="zhezu-article__date-item">
                <span class="zhezu-article__date-label">
                    {translate key="plugins.themes.zhezujournal.article.dateSubmitted"}
                </span>
                <span>{$article->getDateSubmitted()|date_format:$dateFormatShort}</span>
            </div>
        {/if}

        {if $publication->getData('datePublished')}
            <div class="zhezu-article__date-item">
                <span class="zhezu-article__date-label">
                    {translate key="plugins.themes.zhezujournal.article.datePublished"}
                </span>
                <span>{$publication->getData('datePublished')|date_format:$dateFormatShort}</span>
            </div>
        {/if}
    </div>

    {* ── PDF Download ── *}
    {if $primaryGalleys|@count}
        <div class="zhezu-article__pdf">
            {foreach from=$primaryGalleys item=galley}
                {if $galley->isPdfGalley()}
                    <a class="zhezu-article__pdf-btn"
                       href="{url page="article" op="download" path=$article->getBestId()|to_array:$galley->getBestGalleyId()}">
                        &#128196; {translate key="plugins.themes.zhezujournal.article.downloadPdf"}
                    </a>
                {/if}
            {/foreach}
        </div>
    {/if}

    {* ── Supplementary Galleys ── *}
    {if $supplementaryGalleys|@count}
        <div class="zhezu-article__galleys-extra">
            {foreach from=$supplementaryGalleys item=galley}
                <a class="zhezu-article__galley-link"
                   href="{url page="article" op="download" path=$article->getBestId()|to_array:$galley->getBestGalleyId()}">
                    {$galley->getGalleyLabel()|escape}
                </a>
            {/foreach}
        </div>
    {/if}

    {* ── View / Download Stats ── *}
    <div class="zhezu-article__stats">
        <div class="zhezu-article__stat">
            <span class="zhezu-article__stat-count">{$article->getViews()|default:0}</span>
            <span class="zhezu-article__stat-label">
                {translate key="plugins.themes.zhezujournal.article.views"}
            </span>
        </div>
        <div class="zhezu-article__stat">
            <span class="zhezu-article__stat-count">{$article->getDownloads()|default:0}</span>
            <span class="zhezu-article__stat-label">
                {translate key="plugins.themes.zhezujournal.article.downloads"}
            </span>
        </div>
    </div>

    {* ── Abstract ── *}
    {if $publication->getLocalizedData('abstract')}
        <section class="zhezu-article__abstract">
            <h2 class="zhezu-article__abstract-title">
                {translate key="plugins.themes.zhezujournal.article.abstract"}
            </h2>
            <div class="zhezu-article__abstract-text" data-zhezu-collapsible data-max-height="300">
                {$publication->getLocalizedData('abstract')|strip_unsafe_html}
            </div>
            <button class="zhezu-article__abstract-toggle" type="button"
                    data-zhezu-collapsible-toggle hidden>
                {translate key="plugins.themes.zhezujournal.article.showMore"}
            </button>
        </section>
    {/if}

    {* ── Keywords ── *}
    {if $publication->getLocalizedData('keywords')|@count}
        <section class="zhezu-article__keywords">
            <h2 class="zhezu-article__keywords-title">
                {translate key="plugins.themes.zhezujournal.article.keywords"}
            </h2>
            <ul class="zhezu-article__keywords-list">
                {foreach from=$publication->getLocalizedData('keywords') item=keyword}
                    <li class="zhezu-article__keyword">
                        <a href="{url page="search" op="search" params=['query' => $keyword]}">
                            {$keyword|escape}
                        </a>
                    </li>
                {/foreach}
            </ul>
        </section>
    {/if}

    {* ── References ── *}
    {if $parsedCitations && $parsedCitations->getCount()}
        <section class="zhezu-article__references">
            <h2 class="zhezu-article__references-title">
                {translate key="plugins.themes.zhezujournal.article.references"}
            </h2>
            <ol class="zhezu-article__references-list">
                {iterate from=parsedCitations item=citation}
                    <li class="zhezu-article__reference-item">
                        {$citation->getCitationWithLinks()|strip_unsafe_html}
                    </li>
                {/iterate}
            </ol>
        </section>
    {elseif $publication->getData('citationsRaw')}
        <section class="zhezu-article__references">
            <h2 class="zhezu-article__references-title">
                {translate key="plugins.themes.zhezujournal.article.references"}
            </h2>
            <div class="zhezu-article__references-raw">
                {$publication->getData('citationsRaw')|escape|nl2br}
            </div>
        </section>
    {/if}

    {* ── License ── *}
    {if $licenseUrl}
        <section class="zhezu-article__license">
            <h2 class="zhezu-article__license-title">
                {translate key="plugins.themes.zhezujournal.article.license"}
            </h2>
            <p class="zhezu-article__license-text">
                {if $ccLicenseBadge}
                    {$ccLicenseBadge}
                {else}
                    <a href="{$licenseUrl|escape}" target="_blank" rel="noopener license">
                        {$licenseUrl|escape}
                    </a>
                {/if}
            </p>
            {if $copyrightHolder}
                <p class="zhezu-article__copyright">
                    {translate key="submission.copyrightStatement"
                        copyrightHolder=$copyrightHolder
                        copyrightYear=$copyrightYear}
                </p>
            {/if}
        </section>
    {/if}

    {* ── How to Cite ── *}
    <section class="zhezu-article__citation">
        <h2 class="zhezu-article__citation-title">
            {translate key="plugins.themes.zhezujournal.article.howToCite"}
        </h2>
        <div class="zhezu-article__citation-block" id="articleCitation">
            {$citation|escape}
        </div>
        <button class="zhezu-article__citation-copy" type="button"
                data-clipboard-target="#articleCitation"
                aria-label="{translate key="plugins.themes.zhezujournal.article.copyCitation"}">
            {translate key="plugins.themes.zhezujournal.article.copyCitation"}
        </button>
    </section>

</main>

{include file="frontend/components/footer.tpl"}
